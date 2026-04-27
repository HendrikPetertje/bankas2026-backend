defmodule Bankas2026BackendWeb.UserAuthController do
  use Bankas2026BackendWeb, :controller

  alias Ecto.Multi
  alias Bankas2026Backend.Accounts
  alias Bankas2026Backend.Accounts.JWT
  alias Bankas2026Backend.Farms
  alias Bankas2026Backend.Repo

  def sign_up(conn, params) do
    case register_user(params) do
      {:ok, assigns} ->
        conn
        |> put_status(:created)
        |> render(:auth, assigns)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: translate_errors(changeset)})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{detail: error_detail(reason)}})
    end
  end

  def login(conn, params) do
    with {:ok, username, pin} <- validate_login_params(params),
         {:ok, user} <- Accounts.authenticate_user(username, pin),
         {:ok, %{garden: garden}} <- Farms.get_farm_by_user_id(user.id),
         {:ok, token, _claims} <- JWT.create_token(user) do
      render(conn, :auth, token: token, garden: garden)
    else
      {:error, :invalid_login_params} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{detail: "Invalid login parameters"}})

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{reason: "invalid credentials"})

      {:error, :too_many_login_attempts} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{reason: "to many login attempts"})

      {:error, :not_found} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{detail: "Farm not found for user"}})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: %{detail: error_detail(reason)}})
    end
  end

  def options(conn, _params) do
    send_resp(conn, :no_content, "")
  end

  defp register_user(params) do
    Multi.new()
    |> Multi.run(:user, fn _repo, _changes -> Accounts.create_user(params) end)
    |> Multi.run(:farm, fn _repo, %{user: user} -> Farms.create_farm(user.id) end)
    |> Multi.run(:token, fn _repo, %{user: user} ->
      case JWT.create_token(user) do
        {:ok, token, _claims} -> {:ok, token}
        {:error, reason} -> {:error, reason}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{farm: %{garden: garden}, token: token}} -> {:ok, %{token: token, garden: garden}}
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp validate_login_params(%{"username" => username, "pin" => pin})
       when is_binary(username) and is_binary(pin) do
    {:ok, username, pin}
  end

  defp validate_login_params(_params), do: {:error, :invalid_login_params}

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%\{(\w+)\}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp error_detail(reason) when is_atom(reason) do
    reason
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp error_detail(%Ecto.Changeset{}), do: "Validation failed"
  defp error_detail(_reason), do: "Request could not be processed"
end

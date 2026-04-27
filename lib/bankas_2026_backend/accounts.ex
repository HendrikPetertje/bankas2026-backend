defmodule Bankas2026Backend.Accounts do
  @moduledoc """
  Shared account persistence and authentication.
  """

  import Ecto.Query, warn: false

  alias Bankas2026Backend.Accounts.JWT
  alias Bankas2026Backend.Accounts.User
  alias Bankas2026Backend.Repo

  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(attrs) do
    %User{}
    |> User.create_changeset(attrs)
    |> Repo.insert()
  end

  @spec update_user(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @spec authenticate_user(String.t(), String.t()) ::
          {:ok, User.t()} | {:error, :invalid_credentials}
  def authenticate_user(username, pin)

  def authenticate_user(username, pin) when is_binary(username) and is_binary(pin) do
    normalized_username = User.normalize_username(username)

    case Repo.one(from user in User, where: user.username == ^normalized_username) do
      %User{} = user ->
        if Bcrypt.verify_pass(pin, user.pincode_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end

      nil ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  def authenticate_user(_, _), do: {:error, :invalid_credentials}

  @spec get_user_from_jwt(String.t()) :: {:ok, User.t()} | {:error, term()}
  def get_user_from_jwt(token) when is_binary(token) do
    with {:ok, claims} <- JWT.validate_token(token),
         {:ok, user_id} <- fetch_subject(claims),
         %User{} = user <- Repo.get(User, user_id) do
      {:ok, user}
    else
      {:error, _} = error -> error
      nil -> {:error, :user_not_found}
    end
  end

  def get_user_from_jwt(_), do: {:error, :invalid_token}

  defp fetch_subject(%{"sub" => user_id}) when is_binary(user_id), do: {:ok, user_id}
  defp fetch_subject(_claims), do: {:error, :invalid_token}
end

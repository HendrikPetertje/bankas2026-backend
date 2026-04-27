defmodule Bankas2026Backend.Accounts do
  @moduledoc """
  Shared account persistence and authentication.
  """

  import Ecto.Query, warn: false

  alias Bankas2026Backend.Accounts.JWT
  alias Bankas2026Backend.Accounts.User
  alias Bankas2026Backend.Repo

  @lockout_attempt_threshold 5
  @lockout_window_seconds 600

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
          {:ok, User.t()} | {:error, :invalid_credentials | :too_many_login_attempts}
  def authenticate_user(username, pin)

  def authenticate_user(username, pin) when is_binary(username) and is_binary(pin) do
    normalized_username = User.normalize_username(username)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    case Repo.one(from user in User, where: user.username == ^normalized_username) do
      %User{} = user ->
        cond do
          lockout_active?(user, now) ->
            {:error, :too_many_login_attempts}

          Bcrypt.verify_pass(pin, user.pincode_hash) ->
            reset_failed_login_tracking(user)

          true ->
            record_failed_login_attempt(user, now)
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

  defp lockout_active?(user, now) do
    user.failed_login_attempts >= @lockout_attempt_threshold and
      not tracking_expired?(user, now)
  end

  defp tracking_expired?(%User{last_failed_login_attempt_at: nil}, _now), do: true

  defp tracking_expired?(%User{last_failed_login_attempt_at: last_attempt_at}, now) do
    DateTime.diff(now, last_attempt_at, :second) >= @lockout_window_seconds
  end

  defp reset_failed_login_tracking(user) do
    user
    |> Ecto.Changeset.change(failed_login_attempts: 0, last_failed_login_attempt_at: nil)
    |> Repo.update()
    |> case do
      {:ok, reset_user} -> {:ok, reset_user}
      {:error, _changeset} -> {:error, :invalid_credentials}
    end
  end

  defp record_failed_login_attempt(user, now) do
    attempts = if tracking_expired?(user, now), do: 1, else: user.failed_login_attempts + 1

    user
    |> Ecto.Changeset.change(
      failed_login_attempts: attempts,
      last_failed_login_attempt_at: now
    )
    |> Repo.update()
    |> case do
      {:ok, _user} -> {:error, :invalid_credentials}
      {:error, _changeset} -> {:error, :invalid_credentials}
    end
  end

  defp fetch_subject(%{"sub" => user_id}) when is_binary(user_id), do: {:ok, user_id}
  defp fetch_subject(_claims), do: {:error, :invalid_token}
end

defmodule Bankas2026Backend.Accounts.User do
  use Ecto.Schema

  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "accounts_users" do
    field :username, :string
    field :pincode_hash, :string
    field :pin, :string, virtual: true
    field :failed_login_attempts, :integer, default: 0
    field :last_failed_login_attempt_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @spec create_changeset(t(), map()) :: Ecto.Changeset.t()
  def create_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :pin])
    |> normalize_username_change()
    |> validate_required([:username, :pin])
    |> validate_username()
    |> validate_pin()
    |> put_pin_hash()
    |> validate_required([:pincode_hash])
    |> unique_constraint(:username)
  end

  @spec update_changeset(t(), map()) :: Ecto.Changeset.t()
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :pin])
    |> normalize_username_change()
    |> validate_username()
    |> validate_pin()
    |> put_pin_hash()
    |> unique_constraint(:username)
  end

  @spec normalize_username(String.t()) :: String.t()
  def normalize_username(username) when is_binary(username) do
    username
    |> String.trim()
    |> String.downcase()
  end

  defp normalize_username_change(changeset) do
    update_change(changeset, :username, &normalize_username/1)
  end

  defp validate_username(changeset) do
    validate_length(changeset, :username, min: 6)
  end

  defp validate_pin(changeset) do
    validate_change(changeset, :pin, fn :pin, pin ->
      if String.match?(pin, ~r/^\d{6}$/) do
        []
      else
        [pin: "must be exactly 6 numeric characters"]
      end
    end)
  end

  defp put_pin_hash(changeset) do
    case {changeset.valid?, get_change(changeset, :pin)} do
      {true, pin} when is_binary(pin) ->
        put_change(changeset, :pincode_hash, Bcrypt.hash_pwd_salt(pin))

      _ ->
        changeset
    end
  end
end

defmodule Bankas2026Backend.Accounts.JWT do
  @moduledoc """
  Signed JWT creation and validation for shared account auth.
  """

  use Joken.Config, default_signer: nil

  alias Bankas2026Backend.Accounts.User

  @impl true
  def token_config do
    default_claims(skip: [:exp, :nbf, :iss, :aud, :jti])
    |> add_claim("sub", nil, &valid_uuid?/1)
    |> add_claim("username", nil, &is_binary/1)
  end

  @spec create_token(User.t()) :: {:ok, String.t(), map()} | {:error, term()}
  def create_token(%User{} = user) do
    generate_and_sign(%{"sub" => user.id, "username" => user.username}, signer())
  end

  @spec validate_token(String.t()) :: {:ok, map()} | {:error, term()}
  def validate_token(token) when is_binary(token) do
    token
    |> strip_bearer_prefix()
    |> verify_and_validate(signer())
  end

  def validate_token(_token), do: {:error, :invalid_token}

  defp signer do
    secret = Application.fetch_env!(:bankas_2026_backend, :jwt_secret)
    Joken.Signer.create("HS256", secret)
  end

  defp strip_bearer_prefix("Bearer " <> token), do: token
  defp strip_bearer_prefix(token), do: token

  defp valid_uuid?(value) when is_binary(value) do
    match?({:ok, _uuid}, Ecto.UUID.cast(value))
  end

  defp valid_uuid?(_value), do: false
end

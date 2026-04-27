defmodule Bankas2026Backend.Accounts.JWTTest do
  use Bankas2026Backend.DataCase, async: true

  alias Bankas2026Backend.Accounts.JWT

  import Bankas2026Backend.AccountsFixtures

  test "creates a signed token with iat, username, and subject claims" do
    user = user_fixture()

    assert {:ok, token, claims} = JWT.create_token(user)
    assert is_binary(token)
    assert claims["sub"] == user.id
    assert claims["username"] == user.username
    assert is_integer(claims["iat"])
  end

  test "validates a token signed with the configured secret" do
    user = user_fixture()
    {:ok, token, _claims} = JWT.create_token(user)

    assert {:ok, claims} = JWT.validate_token(token)
    assert claims["sub"] == user.id
    assert claims["username"] == user.username
  end

  test "rejects a token signed with the wrong secret" do
    user = user_fixture()

    assert {:ok, token, _claims} =
             Joken.generate_and_sign(
               JWT.token_config(),
               %{"sub" => user.id, "username" => user.username},
               Joken.Signer.create("HS256", "wrong_secret"),
               []
             )

    assert {:error, _reason} = JWT.validate_token(token)
  end

  test "rejects a malformed token" do
    assert {:error, _reason} = JWT.validate_token("definitely-not-a-jwt")
  end
end

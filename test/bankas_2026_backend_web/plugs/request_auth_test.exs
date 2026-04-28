defmodule Bankas2026BackendWeb.Plugs.RequestAuthTest do
  use Bankas2026BackendWeb.ConnCase, async: true

  alias Bankas2026Backend.Accounts.JWT
  alias Bankas2026Backend.AccountsFixtures
  alias Bankas2026BackendWeb.Plugs.RequestAuth

  test "assigns current_user for a valid bearer token", %{conn: conn} do
    user = AccountsFixtures.user_fixture()
    {:ok, token, _claims} = JWT.create_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> RequestAuth.call(%{})

    assert conn.assigns.current_user.id == user.id
    refute conn.halted
  end

  test "halts with 401 for missing token", %{conn: conn} do
    conn = RequestAuth.call(conn, %{})

    assert conn.halted
    assert conn.status == 401
    assert Jason.decode!(conn.resp_body) == %{"errors" => %{"detail" => "Unauthorized"}}
  end

  test "halts with 401 for invalid token", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer not-a-token")
      |> RequestAuth.call(%{})

    assert conn.halted
    assert conn.status == 401
    assert Jason.decode!(conn.resp_body) == %{"errors" => %{"detail" => "Unauthorized"}}
  end
end

defmodule Bankas2026BackendWeb.UserAuthControllerTest do
  use Bankas2026BackendWeb.ConnCase, async: true

  alias Bankas2026Backend.AccountsFixtures
  alias Bankas2026Backend.Farms

  test "sign-up creates user and farm and returns token plus garden", %{conn: conn} do
    conn = post(conn, ~p"/api/users/sign-up", %{username: "farmer1", pin: "123456"})

    assert %{
             "token" => token,
             "garden" => %{
               "user_name" => "farmer1",
               "produced_g" => 0,
               "plots" => plots
             }
           } = json_response(conn, 201)

    assert is_binary(token)
    assert length(plots) == 9
  end

  test "sign-up returns validation errors", %{conn: conn} do
    conn = post(conn, ~p"/api/users/sign-up", %{username: "short", pin: "123"})

    assert %{"errors" => errors} = json_response(conn, 422)
    assert "should be at least 6 character(s)" in errors["username"]
    assert "must be exactly 6 numeric characters" in errors["pin"]
  end

  test "sign-up rejects duplicate usernames regardless of case", %{conn: conn} do
    _user = AccountsFixtures.user_fixture(%{username: "farmer1"})

    conn = post(conn, ~p"/api/users/sign-up", %{username: "FARMER1", pin: "123456"})

    assert %{"errors" => errors} = json_response(conn, 422)
    assert "has already been taken" in errors["username"]
  end

  test "login returns token and current garden", %{conn: conn} do
    user = AccountsFixtures.user_fixture(%{username: "farmer1"})
    {:ok, _farm} = Farms.create_farm(user.id)

    conn = post(conn, ~p"/api/users/login", %{username: "FARMER1", pin: "123456"})

    assert %{
             "token" => token,
             "garden" => %{"user_name" => "farmer1", "plots" => plots}
           } = json_response(conn, 200)

    assert is_binary(token)
    assert length(plots) == 9
  end

  test "login rejects invalid credentials", %{conn: conn} do
    user = AccountsFixtures.user_fixture(%{username: "farmer1"})
    {:ok, _farm} = Farms.create_farm(user.id)

    conn = post(conn, ~p"/api/users/login", %{username: "farmer1", pin: "000000"})

    assert %{"reason" => "invalid credentials"} = json_response(conn, 401)
  end

  test "login rejects active lockout", %{conn: conn} do
    user = AccountsFixtures.user_fixture(%{username: "farmer1"})
    {:ok, _farm} = Farms.create_farm(user.id)

    Enum.each(1..5, fn _ ->
      post(build_conn(), ~p"/api/users/login", %{username: "farmer1", pin: "000000"})
    end)

    conn = post(conn, ~p"/api/users/login", %{username: "farmer1", pin: "123456"})

    assert %{"reason" => "to many login attempts"} = json_response(conn, 401)
  end

  test "allowed origins receive CORS headers on API responses", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "http://localhost:3000")
      |> post(~p"/api/users/sign-up", %{username: "farmer1", pin: "123456"})

    assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:3000"]
  end

  test "unknown origins do not receive CORS headers", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "https://unknown.example")
      |> post(~p"/api/users/sign-up", %{username: "short", pin: "123"})

    assert get_resp_header(conn, "access-control-allow-origin") == []
  end

  test "approved-origin OPTIONS preflight succeeds", %{conn: conn} do
    conn =
      conn
      |> put_req_header("origin", "https://lager.bankasviken")
      |> put_req_header("access-control-request-method", "POST")
      |> options(~p"/api/users/login")

    assert response(conn, 204) == ""
    assert get_resp_header(conn, "access-control-allow-origin") == ["https://lager.bankasviken"]
    assert get_resp_header(conn, "access-control-allow-methods") == ["GET, POST, OPTIONS"]

    assert get_resp_header(conn, "access-control-allow-headers") == [
             "authorization, content-type"
           ]
  end
end

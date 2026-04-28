defmodule Bankas2026BackendWeb.FarmsControllerTest do
  use Bankas2026BackendWeb.ConnCase, async: true

  alias Bankas2026Backend.Accounts.JWT
  alias Bankas2026Backend.AccountsFixtures
  alias Bankas2026Backend.Farms

  test "plant-info returns the plant catalog", %{conn: conn} do
    conn = get(conn, ~p"/api/farms/plant-info")

    assert %{"plants" => plants} = json_response(conn, 200)
    assert length(plants) == 4

    lettuce = Enum.find(plants, &(&1["kind"] == "LETTUCE"))
    assert lettuce["growing_time_s"] == 3600
    assert lettuce["weight_g"]["5"] == 1000
  end

  test "farms/me returns the authenticated farm", %{conn: conn} do
    user = AccountsFixtures.user_fixture(%{username: "farmer123"})
    {:ok, _farm} = Farms.create_farm(user.id)
    {:ok, token, _claims} = JWT.create_token(user)

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> get(~p"/api/farms/me")

    assert %{
             "garden" => %{
               "user_name" => "farmer123",
               "produced_g" => 0,
               "plots" => plots
             }
           } = json_response(conn, 200)

    assert length(plots) == 9
  end

  test "farms/me rejects missing token", %{conn: conn} do
    conn = get(conn, ~p"/api/farms/me")

    assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
  end

  test "farms/me rejects invalid token", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer bad-token")
      |> get(~p"/api/farms/me")

    assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
  end
end

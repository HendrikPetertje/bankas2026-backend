defmodule Bankas2026BackendWeb.PlotsControllerTest do
  use Bankas2026BackendWeb.ConnCase, async: true

  alias Bankas2026Backend.Accounts.JWT
  alias Bankas2026Backend.AccountsFixtures
  alias Bankas2026Backend.Farms
  alias Bankas2026Backend.Farms.Garden
  alias Bankas2026Backend.Farms.GardenPlot
  alias Bankas2026Backend.Repo

  test "clean returns the updated garden", %{conn: conn} do
    %{user: user, token: token} = farm_user_with_token()

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> post(~p"/api/farms/plots/1/clean")

    assert %{"garden" => %{"plots" => plots}} = json_response(conn, 200)
    assert Enum.at(plots, 0)["state"] == "CLEANED"
    assert Enum.at(plots, 0)["last_weeds_removed_at"]
    assert user.id
  end

  test "seed returns the updated garden", %{conn: conn} do
    %{user: user, token: token} = farm_user_with_token()
    {:ok, _farm} = Farms.clean_plot(user.id, 1)
    {:ok, _farm} = Farms.water_plot(user.id, 1)

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> post(~p"/api/farms/plots/1/seed", %{plant_kind: "LETTUCE"})

    assert %{"garden" => %{"plots" => plots}} = json_response(conn, 200)
    assert Enum.at(plots, 0)["state"] == "SEEDED"
    assert Enum.at(plots, 0)["plant_kind"] == "LETTUCE"
  end

  test "water returns the updated garden", %{conn: conn} do
    %{token: token} = farm_user_with_token()

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> post(~p"/api/farms/plots/2/water")

    assert %{"garden" => %{"plots" => plots}} = json_response(conn, 200)
    assert Enum.at(plots, 1)["last_watered_at"]
  end

  test "harvest returns the updated garden", %{conn: conn} do
    %{user: user, token: token} = farm_user_with_token()

    prepare_seeded_plot(user.id, 1, %{
      planted_at: hours_ago(7),
      plant_kind: "PUMPKIN",
      water_stars: 5,
      weed_stars: 4
    })

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> post(~p"/api/farms/plots/1/harvest")

    assert %{"garden" => %{"produced_g" => produced_g, "plots" => plots}} =
             json_response(conn, 200)

    assert produced_g > 0
    assert Enum.at(plots, 0)["state"] == "BARREN"
  end

  test "missing token is rejected", %{conn: conn} do
    conn = post(conn, ~p"/api/farms/plots/1/clean")

    assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
  end

  test "invalid token is rejected", %{conn: conn} do
    conn =
      conn
      |> put_req_header("authorization", "Bearer invalid")
      |> post(~p"/api/farms/plots/1/clean")

    assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
  end

  test "invalid plot state returns conflict", %{conn: conn} do
    %{token: token} = farm_user_with_token()

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> post(~p"/api/farms/plots/1/seed", %{plant_kind: "LETTUCE"})

    assert %{"errors" => %{"detail" => "Plot action conflicts with the current plot state"}} =
             json_response(conn, 409)
  end

  test "rule failures return unprocessable entity", %{conn: conn} do
    %{user: user, token: token} = farm_user_with_token()
    prepare_seeded_plot(user.id, 1, %{planted_at: hours_ago(1), plant_kind: "PUMPKIN"})

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)
      |> post(~p"/api/farms/plots/1/harvest")

    assert %{"errors" => %{"detail" => "Plant is not ready for harvest"}} =
             json_response(conn, 422)
  end

  defp farm_user_with_token do
    user = AccountsFixtures.user_fixture()
    {:ok, _farm} = Farms.create_farm(user.id)
    {:ok, token, _claims} = JWT.create_token(user)
    %{user: user, token: token}
  end

  defp prepare_seeded_plot(user_id, plot_number, overrides) do
    garden = Repo.get_by!(Garden, user_id: user_id)
    plot = Repo.get_by!(GardenPlot, garden_id: garden.id, number: plot_number)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    attrs =
      Enum.into(overrides, %{
        state: "SEEDED",
        plant_kind: "LETTUCE",
        planted_at: now,
        last_watered_at: now,
        last_weeds_removed_at: now,
        water_stars: 5,
        weed_stars: 5,
        last_penalty_at: nil
      })

    plot
    |> GardenPlot.action_changeset(attrs)
    |> Repo.update!()
  end

  defp hours_ago(hours) do
    DateTime.utc_now()
    |> DateTime.add(-hours * 3_600, :second)
    |> DateTime.truncate(:second)
  end
end

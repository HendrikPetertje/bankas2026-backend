defmodule Bankas2026Backend.FarmsTest do
  use Bankas2026Backend.DataCase, async: true

  alias Bankas2026Backend.Farms
  alias Bankas2026Backend.Farms.Garden
  alias Bankas2026Backend.Farms.GardenPlot
  alias Bankas2026Backend.Farms.PlantCatalog

  import Bankas2026Backend.FarmsFixtures

  describe "create_farm/1 and get_farm_by_user_id/1" do
    test "creates a farm with 9 barren plots and loads it with user_name" do
      %{user: user} = setup = farm_fixture(%{username: "farmer1"})
      farm = setup.farm

      assert farm.garden.user_name == user.username
      assert farm.garden.produced_g == 0
      assert length(farm.garden.plots) == 9
      assert Enum.map(farm.garden.plots, & &1.number) == Enum.to_list(1..9)
      assert Enum.all?(farm.garden.plots, &(&1.state == "BARREN" and is_nil(&1.last_watered_at)))

      assert {:ok, loaded_farm} = Farms.get_farm_by_user_id(user.id)
      assert loaded_farm == farm
      refute Map.has_key?(loaded_farm.garden, :user_id)
    end
  end

  describe "plot actions" do
    test "cleaning a barren plot turns it cleaned" do
      %{user: user} = farm_fixture()

      assert {:ok, farm} = Farms.clean_plot(user.id, 1)
      plot = Enum.at(farm.garden.plots, 0)

      assert plot.state == "CLEANED"
      assert %DateTime{} = plot.last_weeds_removed_at
    end

    test "cleaning a seeded plot removes weeds without changing state" do
      %{user: user} = farm_fixture()
      prepare_seeded_plot(user.id, 1)

      assert {:ok, farm} = Farms.clean_plot(user.id, 1)
      plot = Enum.at(farm.garden.plots, 0)

      assert plot.state == "SEEDED"
      assert %DateTime{} = plot.last_weeds_removed_at
    end

    test "seeding requires a cleaned and recently watered plot" do
      %{user: user} = farm_fixture()

      assert {:error, :invalid_plot_state} = Farms.seed_plot(user.id, 1, "LETTUCE")

      assert {:ok, _farm} = Farms.clean_plot(user.id, 1)
      assert {:error, :watering_required} = Farms.seed_plot(user.id, 1, "LETTUCE")

      assert {:ok, farm} = Farms.water_plot(user.id, 1)
      assert Enum.at(farm.garden.plots, 0).state == "CLEANED"

      assert {:ok, farm} = Farms.seed_plot(user.id, 1, "LETTUCE")
      plot = Enum.at(farm.garden.plots, 0)

      assert plot.state == "SEEDED"
      assert plot.plant_kind == "LETTUCE"
      assert plot.water_stars == 5
      assert plot.weed_stars == 5
      assert %DateTime{} = plot.planted_at
    end

    test "watering updates last_watered_at" do
      %{user: user} = farm_fixture()

      assert {:ok, farm} = Farms.water_plot(user.id, 2)
      assert %DateTime{} = Enum.at(farm.garden.plots, 1).last_watered_at
    end

    test "harvest rejects immature plots" do
      %{user: user} = farm_fixture()
      prepare_seeded_plot(user.id, 1)

      assert {:error, :not_ready_for_harvest} = Farms.harvest_plot(user.id, 1)
    end

    test "harvest uses plant catalog output and resets the plot" do
      %{user: user} = farm_fixture()

      prepare_seeded_plot(user.id, 1, %{
        planted_at: hours_ago(7),
        plant_kind: "PUMPKIN",
        water_stars: 5,
        weed_stars: 4
      })

      assert {:ok, farm} = Farms.harvest_plot(user.id, 1)

      plot = Enum.at(farm.garden.plots, 0)

      assert farm.garden.produced_g ==
               PlantCatalog.fetch("PUMPKIN") |> elem(1) |> Map.fetch!(:weight_g) |> Map.fetch!(4)

      assert plot.state == "BARREN"
      assert is_nil(plot.plant_kind)
      assert is_nil(plot.planted_at)
      assert is_nil(plot.water_stars)
      assert is_nil(plot.weed_stars)
    end

    test "invalid plot transitions are rejected" do
      %{user: user} = farm_fixture()

      assert {:ok, _farm} = Farms.clean_plot(user.id, 1)
      assert {:error, :invalid_plot_state} = Farms.clean_plot(user.id, 1)
      assert {:error, :invalid_plant_kind} = Farms.seed_plot(user.id, 1, "POTATO")
    end

    test "pre-action penalties reduce stars and respect cooldown" do
      %{user: user} = farm_fixture()

      prepare_seeded_plot(user.id, 1, %{
        plant_kind: "LETTUCE",
        planted_at: hours_ago(3),
        last_watered_at: hours_ago(3),
        last_weeds_removed_at: hours_ago(2),
        water_stars: 5,
        weed_stars: 5,
        last_penalty_at: nil
      })

      assert {:ok, farm} = Farms.water_plot(user.id, 1)
      plot = Enum.at(farm.garden.plots, 0)

      assert plot.water_stars == 1
      assert plot.weed_stars == 4

      assert {:ok, farm} = Farms.clean_plot(user.id, 1)
      plot = Enum.at(farm.garden.plots, 0)

      assert plot.water_stars == 1
      assert plot.weed_stars == 4
    end
  end

  defp prepare_seeded_plot(user_id, plot_number, overrides \\ %{}) do
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

defmodule Bankas2026Backend.Repo.Migrations.CreateFarmsGardenPlots do
  use Ecto.Migration

  def change do
    create table(:farms_garden_plots, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :garden_id, references(:farms_gardens, type: :uuid, on_delete: :delete_all), null: false
      add :number, :integer, null: false
      add :state, :string, null: false
      add :plant_kind, :string
      add :planted_at, :utc_datetime
      add :last_watered_at, :utc_datetime
      add :last_weeds_removed_at, :utc_datetime
      add :water_stars, :integer
      add :weed_stars, :integer
      add :last_penalty_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:farms_garden_plots, [:garden_id, :number])

    create constraint(:farms_garden_plots, :farms_garden_plots_number_range,
             check: "number >= 1 AND number <= 9"
           )

    create constraint(:farms_garden_plots, :farms_garden_plots_state_valid,
             check: "state IN ('BARREN', 'CLEANED', 'SEEDED')"
           )

    create constraint(:farms_garden_plots, :farms_garden_plots_plant_kind_valid,
             check:
               "plant_kind IS NULL OR plant_kind IN ('LETTUCE', 'TOMATO', 'CARROT', 'PUMPKIN')"
           )

    create constraint(:farms_garden_plots, :farms_garden_plots_water_stars_range,
             check: "water_stars IS NULL OR (water_stars >= 1 AND water_stars <= 5)"
           )

    create constraint(:farms_garden_plots, :farms_garden_plots_weed_stars_range,
             check: "weed_stars IS NULL OR (weed_stars >= 1 AND weed_stars <= 5)"
           )
  end
end

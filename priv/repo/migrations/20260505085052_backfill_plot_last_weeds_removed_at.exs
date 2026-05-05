defmodule Bankas2026Backend.Repo.Migrations.BackfillPlotLastWeedsRemovedAt do
  use Ecto.Migration

  def up do
    execute("""
    UPDATE farms_garden_plots AS plot
    SET last_weeds_removed_at = COALESCE(plot.inserted_at, garden.inserted_at, plot.updated_at)
    FROM farms_gardens AS garden
    WHERE plot.garden_id = garden.id
      AND plot.last_weeds_removed_at IS NULL
    """)

    alter table(:farms_garden_plots) do
      modify :last_weeds_removed_at, :utc_datetime, null: false
    end
  end

  def down do
    alter table(:farms_garden_plots) do
      modify :last_weeds_removed_at, :utc_datetime, null: true
    end
  end
end

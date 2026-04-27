defmodule Bankas2026Backend.Farms.GardenPlot do
  use Ecto.Schema

  import Ecto.Changeset

  alias Bankas2026Backend.Farms.Garden
  alias Bankas2026Backend.Farms.PlantCatalog

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @states ~w(BARREN CLEANED SEEDED)

  @type t :: %__MODULE__{}

  schema "farms_garden_plots" do
    field :number, :integer
    field :state, :string
    field :plant_kind, :string
    field :planted_at, :utc_datetime
    field :last_watered_at, :utc_datetime
    field :last_weeds_removed_at, :utc_datetime
    field :water_stars, :integer
    field :weed_stars, :integer
    field :last_penalty_at, :utc_datetime

    belongs_to :garden, Garden

    timestamps(type: :utc_datetime)
  end

  @spec create_changeset(t(), map()) :: Ecto.Changeset.t()
  def create_changeset(plot, attrs) do
    plot
    |> cast(attrs, [
      :garden_id,
      :number,
      :state,
      :plant_kind,
      :planted_at,
      :last_watered_at,
      :last_weeds_removed_at,
      :water_stars,
      :weed_stars,
      :last_penalty_at
    ])
    |> validate_required([:garden_id, :number, :state])
    |> validate_inclusion(:state, @states)
    |> validate_number(:number, greater_than_or_equal_to: 1, less_than_or_equal_to: 9)
    |> validate_inclusion(:plant_kind, PlantCatalog.kinds())
    |> validate_number(:water_stars, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:weed_stars, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_plot_consistency()
    |> unique_constraint(:number, name: :farms_garden_plots_garden_id_number_index)
  end

  @spec action_changeset(t(), map()) :: Ecto.Changeset.t()
  def action_changeset(plot, attrs) do
    plot
    |> cast(attrs, [
      :state,
      :plant_kind,
      :planted_at,
      :last_watered_at,
      :last_weeds_removed_at,
      :water_stars,
      :weed_stars,
      :last_penalty_at
    ])
    |> validate_required([:state])
    |> validate_inclusion(:state, @states)
    |> validate_inclusion(:plant_kind, PlantCatalog.kinds())
    |> validate_number(:water_stars, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_number(:weed_stars, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_plot_consistency()
  end

  defp validate_plot_consistency(changeset) do
    state = get_field(changeset, :state)
    plant_kind = get_field(changeset, :plant_kind)
    planted_at = get_field(changeset, :planted_at)
    water_stars = get_field(changeset, :water_stars)
    weed_stars = get_field(changeset, :weed_stars)

    if state == "SEEDED" do
      validate_required(changeset, [:plant_kind, :planted_at, :water_stars, :weed_stars])
    else
      if plant_kind || planted_at || water_stars || weed_stars do
        add_error(changeset, :state, "non-seeded plots cannot carry planted data or stars")
      else
        changeset
      end
    end
  end
end

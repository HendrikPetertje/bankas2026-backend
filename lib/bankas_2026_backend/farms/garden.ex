defmodule Bankas2026Backend.Farms.Garden do
  use Ecto.Schema

  import Ecto.Changeset

  alias Bankas2026Backend.Accounts.User
  alias Bankas2026Backend.Farms.GardenPlot

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @type t :: %__MODULE__{}

  schema "farms_gardens" do
    field :produced_g, :integer, default: 0

    belongs_to :user, User
    has_many :plots, GardenPlot

    timestamps(type: :utc_datetime)
  end

  @spec create_changeset(t(), map()) :: Ecto.Changeset.t()
  def create_changeset(garden, attrs) do
    garden
    |> cast(attrs, [:user_id, :produced_g])
    |> validate_required([:user_id])
    |> validate_number(:produced_g, greater_than_or_equal_to: 0)
    |> unique_constraint(:user_id)
  end

  @spec produced_changeset(t(), map()) :: Ecto.Changeset.t()
  def produced_changeset(garden, attrs) do
    garden
    |> cast(attrs, [:produced_g])
    |> validate_required([:produced_g])
    |> validate_number(:produced_g, greater_than_or_equal_to: 0)
  end
end

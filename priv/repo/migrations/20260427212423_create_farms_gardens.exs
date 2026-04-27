defmodule Bankas2026Backend.Repo.Migrations.CreateFarmsGardens do
  use Ecto.Migration

  def change do
    create table(:farms_gardens, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:accounts_users, type: :uuid, on_delete: :delete_all), null: false
      add :produced_g, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:farms_gardens, [:user_id])
  end
end

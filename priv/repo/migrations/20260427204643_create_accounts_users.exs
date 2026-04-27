defmodule Bankas2026Backend.Repo.Migrations.CreateAccountsUsers do
  use Ecto.Migration

  def change do
    create table(:accounts_users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :username, :string, null: false
      add :pincode_hash, :string, null: false
      add :failed_login_attempts, :integer, null: false, default: 0
      add :last_failed_login_attempt_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:accounts_users, [:username])
  end
end

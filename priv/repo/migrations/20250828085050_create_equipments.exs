defmodule Spato.Repo.Migrations.CreateEquipments do
  use Ecto.Migration

  def change do
    create table(:equipments) do
      add :name, :string
      add :type, :string
      add :photo_url, :string
      add :serial_number, :string
      add :total_quantity, :integer
      add :status, :string
      add :created_by_user_id, references(:users, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:equipments, [:created_by_user_id])
    create index(:equipments, [:user_id])
  end
end

defmodule Spato.Repo.Migrations.CreateVehicles do
  use Ecto.Migration

  def change do
    create table(:vehicles) do
      add :name, :string
      add :type, :string
      add :photo_url, :string
      add :vehicle_model, :string
      add :plate_number, :string
      add :status, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:vehicles, [:user_id])
  end
end

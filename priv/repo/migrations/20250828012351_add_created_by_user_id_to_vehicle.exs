defmodule Spato.Repo.Migrations.AddCreatedByUserIdToVehicle do
  use Ecto.Migration

  def change do
    alter table(:vehicles) do
      add :created_by_id, references(:users, on_delete: :nothing)
    end

    create index(:vehicles, [:created_by_id])
  end
end

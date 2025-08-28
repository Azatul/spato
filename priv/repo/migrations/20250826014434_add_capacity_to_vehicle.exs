defmodule Spato.Repo.Migrations.AddCapacityToVehicle do
  use Ecto.Migration

  def change do
    alter table(:vehicles) do
      add :capacity, :integer
    end

  end
end

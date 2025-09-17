defmodule Spato.Repo.Migrations.AddUniqueIndexToVehicleName do
  use Ecto.Migration

  def change do
    create unique_index(:vehicles, [:name])
  end
end

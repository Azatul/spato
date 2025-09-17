defmodule Spato.Repo.Migrations.AddUniqueIndexToVehicleNameCI do
  use Ecto.Migration

  def change do
    # Drop the old case-sensitive index first
    drop_if_exists unique_index(:vehicles, [:name])

    # Create a case-insensitive index
    create unique_index(:vehicles, ["lower(name)"], name: :vehicles_name_lower_index)
  end
end

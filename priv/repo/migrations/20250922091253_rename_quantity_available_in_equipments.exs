defmodule Spato.Repo.Migrations.RenameQuantityAvailableInEquipments do
  use Ecto.Migration

  def change do
    rename table(:equipments), :quantity_available, to: :total_quantity
  end
end

defmodule Spato.Repo.Migrations.RenameCreatedByUserIdInEquipments do
  use Ecto.Migration

  def change do
    rename table(:equipments), :created_by_user_id, to: :created_by_id
  end
end

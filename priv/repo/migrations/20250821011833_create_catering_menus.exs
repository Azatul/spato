defmodule Spato.Repo.Migrations.CreateCateringMenus do
  use Ecto.Migration

  def change do
    create table(:catering_menus) do
      add :name, :string
      add :type, :string
      add :description, :text
      add :price_per_head, :decimal
      add :photo_url, :string
      add :status, :string
      add :created_by_user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:catering_menus, [:created_by_user_id])
  end
end

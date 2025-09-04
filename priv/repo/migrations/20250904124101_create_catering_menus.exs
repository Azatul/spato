defmodule Spato.Repo.Migrations.CreateCateringMenus do
  use Ecto.Migration

  def change do
    create table(:catering_menus) do
      add :name, :string
      add :description, :text
      add :price_per_head, :decimal
      add :status, :string
      add :photo_url, :string
      add :created_by_id, references(:users, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:catering_menus, [:created_by_id])
    create index(:catering_menus, [:user_id])
  end
end

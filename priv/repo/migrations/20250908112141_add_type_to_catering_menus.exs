defmodule Spato.Repo.Migrations.AddTypeToCateringMenus do
  use Ecto.Migration

  def change do
    alter table(:catering_menus) do
      add :type, :string
    end
  end
end

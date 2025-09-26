defmodule Spato.Repo.Migrations.AddFieldsToDepartments do
  use Ecto.Migration

  def change do
    alter table(:departments) do
      add :head_manager, :string
      add :location, :string
      add :description, :text
    end
  end

end

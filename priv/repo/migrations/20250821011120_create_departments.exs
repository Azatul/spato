defmodule Spato.Repo.Migrations.CreateDepartments do
  use Ecto.Migration

  def change do
    create table(:departments) do
      add :name, :string
      add :code, :string

      timestamps(type: :utc_datetime)

      create unique_index(:departments, [:code])
    end
  end
end

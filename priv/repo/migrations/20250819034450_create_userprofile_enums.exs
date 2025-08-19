defmodule Spato.Repo.Migrations.CreateUserprofileEnums do
  use Ecto.Migration

  def up do
    execute "CREATE TYPE gender_enum AS ENUM ('male', 'female');"
    execute "CREATE TYPE employment_status_enum AS ENUM ('full_time', 'part_time', 'contract', 'intern');"
  end

  def down do
    execute "DROP TYPE gender_enum;"
    execute "DROP TYPE employment_status_enum;"
  end
end

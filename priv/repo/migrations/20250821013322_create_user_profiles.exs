defmodule Spato.Repo.Migrations.CreateUserProfiles do
  use Ecto.Migration

  def change do
    create table(:user_profiles) do
      add :full_name, :string
      add :dob, :date
      add :ic_number, :string
      add :position, :string
      add :employment_status, :string
      add :date_joined, :date
      add :profile_picture_url, :string
      add :last_seen_at, :utc_datetime
      add :user_id, references(:users, on_delete: :nothing)
      add :department_id, references(:departments, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:user_profiles, [:user_id])
    create index(:user_profiles, [:department_id])
  end
end

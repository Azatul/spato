defmodule Spato.Repo.Migrations.CreateMeetingRooms do
  use Ecto.Migration

  def change do
    create table(:meeting_rooms) do
      add :name, :string
      add :location, :string
      add :capacity, :integer
      add :available_facility, :string
      add :photo_url, :string
      add :status, :string
      add :created_by_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:meeting_rooms, [:created_by_id])
  end
end

defmodule Spato.Repo.Migrations.CreateMeetingRoomBookings do
  use Ecto.Migration

  def change do
    create table(:meeting_room_bookings) do
      add :purpose, :text
      add :participants, :integer
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime
      add :status, :string
      add :notes, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :meeting_room_id, references(:meeting_rooms, on_delete: :nothing)
      add :approved_by_user_id, references(:users, on_delete: :nothing)
      add :cancelled_by_user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:meeting_room_bookings, [:user_id])
    create index(:meeting_room_bookings, [:meeting_room_id])
    create index(:meeting_room_bookings, [:approved_by_user_id])
    create index(:meeting_room_bookings, [:cancelled_by_user_id])
  end
end

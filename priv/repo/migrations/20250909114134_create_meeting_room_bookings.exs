defmodule Spato.Repo.Migrations.CreateMeetingRoomBookings do
  use Ecto.Migration

  def change do
    create table(:meeting_room_bookings) do
      add :purpose, :text
      add :participants, :integer
      add :start_time, :naive_datetime
      add :end_time, :naive_datetime
      add :is_recurring, :boolean, default: false, null: false
      add :recurrence_pattern, :text
      add :status, :string
      add :notes, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :room_id, references(:meeting_rooms, on_delete: :nothing)
      add :approved_by_user_id, references(:users, on_delete: :nothing)
      add :cancelled_by_user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:meeting_room_bookings, [:user_id])
    create index(:meeting_room_bookings, [:room_id])
    create index(:meeting_room_bookings, [:approved_by_user_id])
    create index(:meeting_room_bookings, [:cancelled_by_user_id])
  end
end

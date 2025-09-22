defmodule Spato.Repo.Migrations.RenameRoomIdToMeetingRoomId do
  use Ecto.Migration

  def change do
    alter table(:meeting_room_bookings) do
      remove :room_id
      add :meeting_room_id, references(:meeting_rooms, on_delete: :nothing)
    end
  end
end

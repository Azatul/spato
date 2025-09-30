defmodule Spato.Repo.Migrations.AddRejectionReasonToMeetingRoomAndCateringBookings do
  use Ecto.Migration

  def change do
    alter table(:meeting_room_bookings) do
      add :rejection_reason, :text
    end

    alter table(:catering_bookings) do
      add :rejection_reason, :text
    end
  end

end

defmodule Spato.Repo.Migrations.AddExclusionConstraintToMeetingRoomBookings do
  use Ecto.Migration

  def change do
    # Ensure the extension exists
    execute("CREATE EXTENSION IF NOT EXISTS btree_gist;")

    # Add exclusion constraint to prevent overlapping bookings
    execute("""
    ALTER TABLE meeting_room_bookings
      ADD CONSTRAINT no_overlapping_meeting_room_bookings
      EXCLUDE USING gist (
        meeting_room_id WITH =,
        tsrange(start_time, end_time) WITH &&
      )
      WHERE (status IN ('pending', 'approved'));
    """)
  end
end

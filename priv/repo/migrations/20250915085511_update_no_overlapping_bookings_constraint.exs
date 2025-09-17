defmodule Spato.Repo.Migrations.UpdateNoOverlappingBookingsConstraint do
  use Ecto.Migration

  def change do
    # Ensure btree_gist is installed
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"

    # Drop the old constraint safely
    execute "ALTER TABLE vehicle_bookings DROP CONSTRAINT IF EXISTS no_overlapping_bookings"

    # Add the new exclusion constraint with conditional status
    execute """
    ALTER TABLE vehicle_bookings
    ADD CONSTRAINT no_overlapping_bookings
    EXCLUDE USING gist (
      vehicle_id WITH =,
      tsrange(pickup_time, return_time) WITH &&
    )
    WHERE (status IN ('pending', 'approved'))
    """
  end
end

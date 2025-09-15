defmodule Spato.Repo.Migrations.AddNoOverlappingBookingsConstraint do
  use Ecto.Migration

  def change do
    # Enable btree_gist extension (needed for exclusion constraints on ranges + equality)
    execute "CREATE EXTENSION IF NOT EXISTS btree_gist"

    # Add exclusion constraint to prevent overlapping bookings for the same vehicle
    create constraint(:vehicle_bookings, :no_overlapping_bookings,
      exclude: ~s|gist (vehicle_id WITH =, tsrange(pickup_time, return_time) WITH &&)|
    )
  end
end

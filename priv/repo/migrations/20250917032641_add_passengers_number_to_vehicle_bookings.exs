defmodule Spato.Repo.Migrations.AddPassengersNumberToVehicleBookings do
  use Ecto.Migration

  def change do
    alter table(:vehicle_bookings) do
      add :passengers_number, :integer, null: false, default: 1
    end
  end
end

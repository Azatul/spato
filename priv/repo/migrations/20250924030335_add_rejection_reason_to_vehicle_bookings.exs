defmodule Spato.Repo.Migrations.AddRejectionReasonToVehicleBookings do
  use Ecto.Migration

  def change do
    alter table(:vehicle_bookings) do
      add :rejection_reason, :text
    end

    alter table(:equipment_bookings) do
      add :rejection_reason, :text
    end
  end

end

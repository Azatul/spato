defmodule Spato.Repo.Migrations.CreateVehicleBookings do
  use Ecto.Migration

  def change do
    create table(:vehicle_bookings) do
      add :purpose, :text
      add :trip_destination, :text
      add :pickup_time, :utc_datetime
      add :return_time, :utc_datetime
      add :status, :string, default: "pending", null: false
      add :additional_notes, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :vehicle_id, references(:vehicles, on_delete: :nothing)
      add :approved_by_user_id, references(:users, on_delete: :nothing)
      add :cancelled_by_user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:vehicle_bookings, [:user_id])
    create index(:vehicle_bookings, [:vehicle_id])
    create index(:vehicle_bookings, [:approved_by_user_id])
    create index(:vehicle_bookings, [:cancelled_by_user_id])
  end
end

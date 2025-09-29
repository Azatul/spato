defmodule Spato.Repo.Migrations.AddReturnFieldsToVehicleAndEquipmentBookings do
  use Ecto.Migration

  def change do
    alter table(:vehicle_bookings) do
      add :return_proof_url, :string
      add :return_notes, :string
      add :return_status, :string, default: "pending" # pending, verified, rejected
      add :return_verified_at, :utc_datetime
      add :return_verified_by_user_id, references(:users, on_delete: :nilify_all)
      add :return_verification_notes, :string
    end

    alter table(:equipment_bookings) do
      add :return_proof_url, :string
      add :return_notes, :string
      add :return_status, :string, default: "pending" # pending, verified, rejected
      add :return_verified_at, :utc_datetime
      add :return_verified_by_user_id, references(:users, on_delete: :nilify_all)
      add :return_verification_notes, :string
    end
  end
end

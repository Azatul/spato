defmodule Spato.Repo.Migrations.CreateEquipmentBookings do
  use Ecto.Migration

  def change do
    create table(:equipment_bookings) do
      add :quantity, :integer
      add :location, :text
      add :usage_date, :date
      add :return_date, :date
      add :usage_time, :time
      add :return_time, :time
      add :additional_notes, :text
      add :condition_before, :text
      add :condition_after, :text
      add :status, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :equipment_id, references(:equipments, on_delete: :nothing)
      add :approved_by_user_id, references(:users, on_delete: :nothing)
      add :cancelled_by_user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:equipment_bookings, [:user_id])
    create index(:equipment_bookings, [:equipment_id])
    create index(:equipment_bookings, [:approved_by_user_id])
    create index(:equipment_bookings, [:cancelled_by_user_id])
  end
end

defmodule Spato.Repo.Migrations.AddUsageAndReturnAtToEquipmentBookings do
  use Ecto.Migration

  def change do
    alter table(:equipment_bookings) do
      add :usage_at, :utc_datetime
      add :return_at, :utc_datetime
    end

    # Optional: backfill old records
    execute """
    UPDATE equipment_bookings
    SET usage_at  = (usage_date::timestamp + usage_time),
        return_at = (return_date::timestamp + return_time)
    WHERE usage_date IS NOT NULL AND usage_time IS NOT NULL
      AND return_date IS NOT NULL AND return_time IS NOT NULL;
    """
  end
end

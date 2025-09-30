defmodule Spato.Repo.Migrations.CreateCateringBookings do
  use Ecto.Migration

  def change do
    create table(:catering_bookings) do
      add :date, :date
      add :time, :time
      add :location, :text
      add :participants, :integer
      add :total_cost, :decimal
      add :special_request, :text
      add :status, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :menu_id, references(:catering_menus, on_delete: :nothing)
      add :approved_by_user_id, references(:users, on_delete: :nothing)
      add :cancelled_by_user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:catering_bookings, [:user_id])
    create index(:catering_bookings, [:menu_id])
    create index(:catering_bookings, [:approved_by_user_id])
    create index(:catering_bookings, [:cancelled_by_user_id])
  end
end

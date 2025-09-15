defmodule Spato.Bookings.VehicleBooking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vehicle_bookings" do
    field :status, :string, default: "pending"
    field :purpose, :string
    field :trip_destination, :string
    field :pickup_time, :utc_datetime
    field :return_time, :utc_datetime
    field :additional_notes, :string

    belongs_to :user, Spato.Accounts.User
    belongs_to :vehicle, Spato.Assets.Vehicle
    belongs_to :approved_by_user, Spato.Accounts.User
    belongs_to :cancelled_by_user, Spato.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vehicle_booking, attrs) do
    vehicle_booking
    |> cast(attrs, [:user_id, :vehicle_id, :approved_by_user_id, :cancelled_by_user_id, :purpose, :trip_destination, :pickup_time, :return_time, :status, :additional_notes])
    |> validate_required([:purpose, :trip_destination, :pickup_time, :return_time, :additional_notes])
    |> validate_inclusion(:status, ["pending", "approved", "rejected", "cancelled", "completed"])
    |> unique_constraint(:vehicle_id, name: :no_overlapping_bookings)
  end

  def human_status("pending"), do: "Menunggu Kelulusan"
  def human_status("approved"), do: "Diluluskan"
  def human_status("rejected"), do: "Ditolak"
  def human_status("cancelled"), do: "Dibatalkan"
  def human_status("completed"), do: "Selesai"
  def human_status(other), do: other
end

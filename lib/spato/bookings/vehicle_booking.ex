defmodule Spato.Bookings.VehicleBooking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vehicle_bookings" do
    field :status, :string
    field :purpose, :string
    field :trip_destination, :string
    field :pickup_time, :utc_datetime
    field :return_time, :utc_datetime
    field :additional_notes, :string
    field :user_id, :id
    field :vehicle_id, :id
    field :approved_by_user_id, :id
    field :cancelled_by_user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vehicle_booking, attrs) do
    vehicle_booking
    |> cast(attrs, [:purpose, :trip_destination, :pickup_time, :return_time, :status, :additional_notes])
    |> validate_required([:purpose, :trip_destination, :pickup_time, :return_time, :status, :additional_notes])
  end
end

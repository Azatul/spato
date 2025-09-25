defmodule Spato.Bookings.VehicleBooking do
  use Ecto.Schema
  import Ecto.Changeset
  alias Spato.Assets.Vehicle
  alias Spato.Repo

  schema "vehicle_bookings" do
    field :status, :string, default: "pending"
    field :purpose, :string
    field :trip_destination, :string
    field :pickup_time, :utc_datetime
    field :return_time, :utc_datetime
    field :additional_notes, :string
    field :passengers_number, :integer
    field :rejection_reason, :string

    belongs_to :user, Spato.Accounts.User
    belongs_to :vehicle, Vehicle
    belongs_to :approved_by_user, Spato.Accounts.User
    belongs_to :cancelled_by_user, Spato.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vehicle_booking, attrs) do
    vehicle_booking
    |> cast(attrs, [
      :rejection_reason,
      :passengers_number,
      :user_id,
      :vehicle_id,
      :approved_by_user_id,
      :cancelled_by_user_id,
      :purpose,
      :trip_destination,
      :pickup_time,
      :return_time,
      :status,
      :additional_notes
    ])
    |> validate_required([:purpose, :trip_destination, :pickup_time, :return_time, :vehicle_id, :passengers_number])
    |> validate_inclusion(:status, ["pending", "approved", "rejected", "cancelled", "completed"])
    |> validate_number(:passengers_number, greater_than: 0)
    |> unique_constraint(:vehicle_id, name: :no_overlapping_bookings)
    |> update_change(:status, &String.downcase/1)
    |> validate_vehicle_capacity()
    |> Spato.Bookings.validate_datetime_order(:pickup_time, :return_time)
  end

  # Ensure passengers do not exceed vehicle capacity
  defp validate_vehicle_capacity(changeset) do
    case {get_field(changeset, :vehicle_id), get_field(changeset, :passengers_number)} do
      {nil, _} -> changeset
      {_, nil} -> changeset
      {vehicle_id, passengers} ->
        case Repo.get(Vehicle, vehicle_id) do
          nil -> changeset
          vehicle ->
            if passengers > vehicle.capacity do
              add_error(changeset, :passengers_number,
                "Bilangan penumpang melebihi kapasiti kenderaan (#{vehicle.capacity})"
              )
            else
              changeset
            end
        end
    end
  end

  def human_status("pending"), do: "Menunggu Kelulusan"
  def human_status("approved"), do: "Diluluskan"
  def human_status("rejected"), do: "Ditolak"
  def human_status("cancelled"), do: "Dibatalkan"
  def human_status("completed"), do: "Selesai"
  def human_status(other), do: other
end

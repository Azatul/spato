defmodule Spato.Bookings.VehicleBooking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vehicle_bookings" do
    field :status, :string
    field :purpose, :string
    field :trip_destination, :string
    field :pickup_time, :naive_datetime
    field :return_time, :naive_datetime
    field :additional_notes, :string
    field :rejection_reason, :string

    belongs_to :user, Spato.Accounts.User
    belongs_to :vehicle, Spato.Assets.Vehicle
    belongs_to :approved_by_user, Spato.Accounts.User
    belongs_to :cancelled_by_user, Spato.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vehicle_booking, attrs) do
    normalized_attrs = normalize_datetime_strings(attrs)

    vehicle_booking
    |> cast(normalized_attrs, [:user_id, :vehicle_id, :approved_by_user_id, :cancelled_by_user_id, :purpose, :trip_destination, :pickup_time, :return_time, :status, :additional_notes, :rejection_reason])
    |> validate_required([:purpose, :trip_destination, :pickup_time, :return_time])
    |> validate_inclusion(:status, ["pending", "approved", "rejected", "cancelled", "completed"])
  end

  defp normalize_datetime_strings(attrs) when is_map(attrs) do
    attrs
    |> maybe_add_seconds("pickup_time")
    |> maybe_add_seconds("return_time")
    |> maybe_add_seconds(:pickup_time)
    |> maybe_add_seconds(:return_time)
  end

  defp maybe_add_seconds(attrs, key) do
    case Map.get(attrs, key) do
      value when is_binary(value) and byte_size(value) == 16 ->
        Map.put(attrs, key, value <> ":00")
      _ ->
        attrs
    end
  end
end

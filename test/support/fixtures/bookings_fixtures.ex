defmodule Spato.BookingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Spato.Bookings` context.
  """

  @doc """
  Generate a vehicle_booking.
  """
  def vehicle_booking_fixture(attrs \\ %{}) do
    {:ok, vehicle_booking} =
      attrs
      |> Enum.into(%{
        additional_notes: "some additional_notes",
        pickup_time: ~U[2025-09-07 13:27:00Z],
        purpose: "some purpose",
        return_time: ~U[2025-09-07 13:27:00Z],
        status: "some status",
        trip_destination: "some trip_destination"
      })
      |> Spato.Bookings.create_vehicle_booking()

    vehicle_booking
  end

  @doc """
  Generate a equipment_booking.
  """
  def equipment_booking_fixture(attrs \\ %{}) do
    {:ok, equipment_booking} =
      attrs
      |> Enum.into(%{
        additional_notes: "some additional_notes",
        condition_after: "some condition_after",
        condition_before: "some condition_before",
        location: "some location",
        quantity: 42,
        return_at: ~U[2025-09-21 06:50:00Z],
        status: "some status",
        usage_at: ~U[2025-09-21 06:50:00Z]
      })
      |> Spato.Bookings.create_equipment_booking()

    equipment_booking
  end
end

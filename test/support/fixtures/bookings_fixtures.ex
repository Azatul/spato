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
        pickup_time: ~N[2025-09-03 12:57:00],
        purpose: "some purpose",
        rejection_reason: "some rejection_reason",
        return_time: ~N[2025-09-03 12:57:00],
        status: "some status",
        trip_destination: "some trip_destination"
      })
      |> Spato.Bookings.create_vehicle_booking()

    vehicle_booking
  end
end

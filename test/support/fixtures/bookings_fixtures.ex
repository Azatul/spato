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
end

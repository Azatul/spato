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
  Generate a catering_booking.
  """
  def catering_booking_fixture(attrs \\ %{}) do
    {:ok, catering_booking} =
      attrs
      |> Enum.into(%{
        date: ~D[2025-09-21],
        location: "some location",
        participants: 42,
        special_request: "some special_request",
        status: "some status",
        time: ~T[14:00:00],
        total_cost: "120.5"
      })
      |> Spato.Bookings.create_catering_booking()

    catering_booking
  end
end

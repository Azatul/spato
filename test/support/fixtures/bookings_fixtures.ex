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

  @doc """
  Generate a meeting_room_booking.
  """
  def meeting_room_booking_fixture(attrs \\ %{}) do
    {:ok, meeting_room_booking} =
      attrs
      |> Enum.into(%{
        end_time: ~U[2025-09-16 12:54:00Z],
        notes: "some notes",
        participants: 42,
        purpose: "some purpose",
        start_time: ~U[2025-09-16 12:54:00Z],
        status: "some status"
      })
      |> Spato.Bookings.create_meeting_room_booking()

    meeting_room_booking
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
        requested_quantity: 42,
        return_at: ~U[2025-09-22 09:02:00Z],
        status: "some status",
        usage_at: ~U[2025-09-22 09:02:00Z]
      })
      |> Spato.Bookings.create_equipment_booking()

    equipment_booking
  end
end

defmodule Spato.BookingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Spato.Bookings` context.
  """

  @doc """
  Generate a meeting_room_booking.
  """
  def meeting_room_booking_fixture(attrs \\ %{}) do
    {:ok, meeting_room_booking} =
      attrs
      |> Enum.into(%{
        end_time: ~N[2025-09-08 11:41:00],
        is_recurring: true,
        notes: "some notes",
        participants: 42,
        purpose: "some purpose",
        recurrence_pattern: "some recurrence_pattern",
        start_time: ~N[2025-09-08 11:41:00],
        status: "some status"
      })
      |> Spato.Bookings.create_meeting_room_booking()

    meeting_room_booking
  end
end

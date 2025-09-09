defmodule Spato.BookingsTest do
  use Spato.DataCase

  alias Spato.Bookings

  describe "meeting_room_bookings" do
    alias Spato.Bookings.MeetingRoomBooking

    import Spato.BookingsFixtures

    @invalid_attrs %{status: nil, purpose: nil, participants: nil, start_time: nil, end_time: nil, is_recurring: nil, recurrence_pattern: nil, notes: nil}

    test "list_meeting_room_bookings/0 returns all meeting_room_bookings" do
      meeting_room_booking = meeting_room_booking_fixture()
      assert Bookings.list_meeting_room_bookings() == [meeting_room_booking]
    end

    test "get_meeting_room_booking!/1 returns the meeting_room_booking with given id" do
      meeting_room_booking = meeting_room_booking_fixture()
      assert Bookings.get_meeting_room_booking!(meeting_room_booking.id) == meeting_room_booking
    end

    test "create_meeting_room_booking/1 with valid data creates a meeting_room_booking" do
      valid_attrs = %{status: "some status", purpose: "some purpose", participants: 42, start_time: ~N[2025-09-08 11:41:00], end_time: ~N[2025-09-08 11:41:00], is_recurring: true, recurrence_pattern: "some recurrence_pattern", notes: "some notes"}

      assert {:ok, %MeetingRoomBooking{} = meeting_room_booking} = Bookings.create_meeting_room_booking(valid_attrs)
      assert meeting_room_booking.status == "some status"
      assert meeting_room_booking.purpose == "some purpose"
      assert meeting_room_booking.participants == 42
      assert meeting_room_booking.start_time == ~N[2025-09-08 11:41:00]
      assert meeting_room_booking.end_time == ~N[2025-09-08 11:41:00]
      assert meeting_room_booking.is_recurring == true
      assert meeting_room_booking.recurrence_pattern == "some recurrence_pattern"
      assert meeting_room_booking.notes == "some notes"
    end

    test "create_meeting_room_booking/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bookings.create_meeting_room_booking(@invalid_attrs)
    end

    test "update_meeting_room_booking/2 with valid data updates the meeting_room_booking" do
      meeting_room_booking = meeting_room_booking_fixture()
      update_attrs = %{status: "some updated status", purpose: "some updated purpose", participants: 43, start_time: ~N[2025-09-09 11:41:00], end_time: ~N[2025-09-09 11:41:00], is_recurring: false, recurrence_pattern: "some updated recurrence_pattern", notes: "some updated notes"}

      assert {:ok, %MeetingRoomBooking{} = meeting_room_booking} = Bookings.update_meeting_room_booking(meeting_room_booking, update_attrs)
      assert meeting_room_booking.status == "some updated status"
      assert meeting_room_booking.purpose == "some updated purpose"
      assert meeting_room_booking.participants == 43
      assert meeting_room_booking.start_time == ~N[2025-09-09 11:41:00]
      assert meeting_room_booking.end_time == ~N[2025-09-09 11:41:00]
      assert meeting_room_booking.is_recurring == false
      assert meeting_room_booking.recurrence_pattern == "some updated recurrence_pattern"
      assert meeting_room_booking.notes == "some updated notes"
    end

    test "update_meeting_room_booking/2 with invalid data returns error changeset" do
      meeting_room_booking = meeting_room_booking_fixture()
      assert {:error, %Ecto.Changeset{}} = Bookings.update_meeting_room_booking(meeting_room_booking, @invalid_attrs)
      assert meeting_room_booking == Bookings.get_meeting_room_booking!(meeting_room_booking.id)
    end

    test "delete_meeting_room_booking/1 deletes the meeting_room_booking" do
      meeting_room_booking = meeting_room_booking_fixture()
      assert {:ok, %MeetingRoomBooking{}} = Bookings.delete_meeting_room_booking(meeting_room_booking)
      assert_raise Ecto.NoResultsError, fn -> Bookings.get_meeting_room_booking!(meeting_room_booking.id) end
    end

    test "change_meeting_room_booking/1 returns a meeting_room_booking changeset" do
      meeting_room_booking = meeting_room_booking_fixture()
      assert %Ecto.Changeset{} = Bookings.change_meeting_room_booking(meeting_room_booking)
    end
  end
end

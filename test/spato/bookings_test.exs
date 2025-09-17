defmodule Spato.BookingsTest do
  use Spato.DataCase

  alias Spato.Bookings

  describe "vehicle_bookings" do
    alias Spato.Bookings.VehicleBooking

    import Spato.BookingsFixtures

    @invalid_attrs %{status: nil, purpose: nil, trip_destination: nil, pickup_time: nil, return_time: nil, additional_notes: nil}

    test "list_vehicle_bookings/0 returns all vehicle_bookings" do
      vehicle_booking = vehicle_booking_fixture()
      assert Bookings.list_vehicle_bookings() == [vehicle_booking]
    end

    test "get_vehicle_booking!/1 returns the vehicle_booking with given id" do
      vehicle_booking = vehicle_booking_fixture()
      assert Bookings.get_vehicle_booking!(vehicle_booking.id) == vehicle_booking
    end

    test "create_vehicle_booking/1 with valid data creates a vehicle_booking" do
      valid_attrs = %{status: "some status", purpose: "some purpose", trip_destination: "some trip_destination", pickup_time: ~U[2025-09-07 13:27:00Z], return_time: ~U[2025-09-07 13:27:00Z], additional_notes: "some additional_notes"}

      assert {:ok, %VehicleBooking{} = vehicle_booking} = Bookings.create_vehicle_booking(valid_attrs)
      assert vehicle_booking.status == "some status"
      assert vehicle_booking.purpose == "some purpose"
      assert vehicle_booking.trip_destination == "some trip_destination"
      assert vehicle_booking.pickup_time == ~U[2025-09-07 13:27:00Z]
      assert vehicle_booking.return_time == ~U[2025-09-07 13:27:00Z]
      assert vehicle_booking.additional_notes == "some additional_notes"
    end

    test "create_vehicle_booking/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bookings.create_vehicle_booking(@invalid_attrs)
    end

    test "update_vehicle_booking/2 with valid data updates the vehicle_booking" do
      vehicle_booking = vehicle_booking_fixture()
      update_attrs = %{status: "some updated status", purpose: "some updated purpose", trip_destination: "some updated trip_destination", pickup_time: ~U[2025-09-08 13:27:00Z], return_time: ~U[2025-09-08 13:27:00Z], additional_notes: "some updated additional_notes"}

      assert {:ok, %VehicleBooking{} = vehicle_booking} = Bookings.update_vehicle_booking(vehicle_booking, update_attrs)
      assert vehicle_booking.status == "some updated status"
      assert vehicle_booking.purpose == "some updated purpose"
      assert vehicle_booking.trip_destination == "some updated trip_destination"
      assert vehicle_booking.pickup_time == ~U[2025-09-08 13:27:00Z]
      assert vehicle_booking.return_time == ~U[2025-09-08 13:27:00Z]
      assert vehicle_booking.additional_notes == "some updated additional_notes"
    end

    test "update_vehicle_booking/2 with invalid data returns error changeset" do
      vehicle_booking = vehicle_booking_fixture()
      assert {:error, %Ecto.Changeset{}} = Bookings.update_vehicle_booking(vehicle_booking, @invalid_attrs)
      assert vehicle_booking == Bookings.get_vehicle_booking!(vehicle_booking.id)
    end

    test "delete_vehicle_booking/1 deletes the vehicle_booking" do
      vehicle_booking = vehicle_booking_fixture()
      assert {:ok, %VehicleBooking{}} = Bookings.delete_vehicle_booking(vehicle_booking)
      assert_raise Ecto.NoResultsError, fn -> Bookings.get_vehicle_booking!(vehicle_booking.id) end
    end

    test "change_vehicle_booking/1 returns a vehicle_booking changeset" do
      vehicle_booking = vehicle_booking_fixture()
      assert %Ecto.Changeset{} = Bookings.change_vehicle_booking(vehicle_booking)
    end
  end

  describe "meeting_room_bookings" do
    alias Spato.Bookings.MeetingRoomBooking

    import Spato.BookingsFixtures

    @invalid_attrs %{status: nil, purpose: nil, participants: nil, start_time: nil, end_time: nil, notes: nil}

    test "list_meeting_room_bookings/0 returns all meeting_room_bookings" do
      meeting_room_booking = meeting_room_booking_fixture()
      assert Bookings.list_meeting_room_bookings() == [meeting_room_booking]
    end

    test "get_meeting_room_booking!/1 returns the meeting_room_booking with given id" do
      meeting_room_booking = meeting_room_booking_fixture()
      assert Bookings.get_meeting_room_booking!(meeting_room_booking.id) == meeting_room_booking
    end

    test "create_meeting_room_booking/1 with valid data creates a meeting_room_booking" do
      valid_attrs = %{status: "some status", purpose: "some purpose", participants: 42, start_time: ~U[2025-09-16 12:54:00Z], end_time: ~U[2025-09-16 12:54:00Z], notes: "some notes"}

      assert {:ok, %MeetingRoomBooking{} = meeting_room_booking} = Bookings.create_meeting_room_booking(valid_attrs)
      assert meeting_room_booking.status == "some status"
      assert meeting_room_booking.purpose == "some purpose"
      assert meeting_room_booking.participants == 42
      assert meeting_room_booking.start_time == ~U[2025-09-16 12:54:00Z]
      assert meeting_room_booking.end_time == ~U[2025-09-16 12:54:00Z]
      assert meeting_room_booking.notes == "some notes"
    end

    test "create_meeting_room_booking/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bookings.create_meeting_room_booking(@invalid_attrs)
    end

    test "update_meeting_room_booking/2 with valid data updates the meeting_room_booking" do
      meeting_room_booking = meeting_room_booking_fixture()
      update_attrs = %{status: "some updated status", purpose: "some updated purpose", participants: 43, start_time: ~U[2025-09-17 12:54:00Z], end_time: ~U[2025-09-17 12:54:00Z], notes: "some updated notes"}

      assert {:ok, %MeetingRoomBooking{} = meeting_room_booking} = Bookings.update_meeting_room_booking(meeting_room_booking, update_attrs)
      assert meeting_room_booking.status == "some updated status"
      assert meeting_room_booking.purpose == "some updated purpose"
      assert meeting_room_booking.participants == 43
      assert meeting_room_booking.start_time == ~U[2025-09-17 12:54:00Z]
      assert meeting_room_booking.end_time == ~U[2025-09-17 12:54:00Z]
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

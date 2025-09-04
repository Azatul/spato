defmodule Spato.BookingsTest do
  use Spato.DataCase

  alias Spato.Bookings

  describe "vehicle_bookings" do
    alias Spato.Bookings.VehicleBooking

    import Spato.BookingsFixtures

    @invalid_attrs %{status: nil, purpose: nil, trip_destination: nil, pickup_time: nil, return_time: nil, additional_notes: nil, rejection_reason: nil}

    test "list_vehicle_bookings/0 returns all vehicle_bookings" do
      vehicle_booking = vehicle_booking_fixture()
      assert Bookings.list_vehicle_bookings() == [vehicle_booking]
    end

    test "get_vehicle_booking!/1 returns the vehicle_booking with given id" do
      vehicle_booking = vehicle_booking_fixture()
      assert Bookings.get_vehicle_booking!(vehicle_booking.id) == vehicle_booking
    end

    test "create_vehicle_booking/1 with valid data creates a vehicle_booking" do
      valid_attrs = %{status: "some status", purpose: "some purpose", trip_destination: "some trip_destination", pickup_time: ~N[2025-09-03 12:57:00], return_time: ~N[2025-09-03 12:57:00], additional_notes: "some additional_notes", rejection_reason: "some rejection_reason"}

      assert {:ok, %VehicleBooking{} = vehicle_booking} = Bookings.create_vehicle_booking(valid_attrs)
      assert vehicle_booking.status == "some status"
      assert vehicle_booking.purpose == "some purpose"
      assert vehicle_booking.trip_destination == "some trip_destination"
      assert vehicle_booking.pickup_time == ~N[2025-09-03 12:57:00]
      assert vehicle_booking.return_time == ~N[2025-09-03 12:57:00]
      assert vehicle_booking.additional_notes == "some additional_notes"
      assert vehicle_booking.rejection_reason == "some rejection_reason"
    end

    test "create_vehicle_booking/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bookings.create_vehicle_booking(@invalid_attrs)
    end

    test "update_vehicle_booking/2 with valid data updates the vehicle_booking" do
      vehicle_booking = vehicle_booking_fixture()
      update_attrs = %{status: "some updated status", purpose: "some updated purpose", trip_destination: "some updated trip_destination", pickup_time: ~N[2025-09-04 12:57:00], return_time: ~N[2025-09-04 12:57:00], additional_notes: "some updated additional_notes", rejection_reason: "some updated rejection_reason"}

      assert {:ok, %VehicleBooking{} = vehicle_booking} = Bookings.update_vehicle_booking(vehicle_booking, update_attrs)
      assert vehicle_booking.status == "some updated status"
      assert vehicle_booking.purpose == "some updated purpose"
      assert vehicle_booking.trip_destination == "some updated trip_destination"
      assert vehicle_booking.pickup_time == ~N[2025-09-04 12:57:00]
      assert vehicle_booking.return_time == ~N[2025-09-04 12:57:00]
      assert vehicle_booking.additional_notes == "some updated additional_notes"
      assert vehicle_booking.rejection_reason == "some updated rejection_reason"
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
end

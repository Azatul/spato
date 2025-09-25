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

  describe "catering_bookings" do
    alias Spato.Bookings.CateringBooking

    import Spato.BookingsFixtures

    @invalid_attrs %{status: nil, date: nil, time: nil, location: nil, participants: nil, total_cost: nil, special_request: nil}

    test "list_catering_bookings/0 returns all catering_bookings" do
      catering_booking = catering_booking_fixture()
      assert Bookings.list_catering_bookings() == [catering_booking]
    end

    test "get_catering_booking!/1 returns the catering_booking with given id" do
      catering_booking = catering_booking_fixture()
      assert Bookings.get_catering_booking!(catering_booking.id) == catering_booking
    end

    test "create_catering_booking/1 with valid data creates a catering_booking" do
      valid_attrs = %{status: "some status", date: ~D[2025-09-21], time: ~T[14:00:00], location: "some location", participants: 42, total_cost: "120.5", special_request: "some special_request"}

      assert {:ok, %CateringBooking{} = catering_booking} = Bookings.create_catering_booking(valid_attrs)
      assert catering_booking.status == "some status"
      assert catering_booking.date == ~D[2025-09-21]
      assert catering_booking.time == ~T[14:00:00]
      assert catering_booking.location == "some location"
      assert catering_booking.participants == 42
      assert catering_booking.total_cost == Decimal.new("120.5")
      assert catering_booking.special_request == "some special_request"
    end

    test "create_catering_booking/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bookings.create_catering_booking(@invalid_attrs)
    end

    test "update_catering_booking/2 with valid data updates the catering_booking" do
      catering_booking = catering_booking_fixture()
      update_attrs = %{status: "some updated status", date: ~D[2025-09-22], time: ~T[15:01:01], location: "some updated location", participants: 43, total_cost: "456.7", special_request: "some updated special_request"}

      assert {:ok, %CateringBooking{} = catering_booking} = Bookings.update_catering_booking(catering_booking, update_attrs)
      assert catering_booking.status == "some updated status"
      assert catering_booking.date == ~D[2025-09-22]
      assert catering_booking.time == ~T[15:01:01]
      assert catering_booking.location == "some updated location"
      assert catering_booking.participants == 43
      assert catering_booking.total_cost == Decimal.new("456.7")
      assert catering_booking.special_request == "some updated special_request"
    end

    test "update_catering_booking/2 with invalid data returns error changeset" do
      catering_booking = catering_booking_fixture()
      assert {:error, %Ecto.Changeset{}} = Bookings.update_catering_booking(catering_booking, @invalid_attrs)
      assert catering_booking == Bookings.get_catering_booking!(catering_booking.id)
    end

    test "delete_catering_booking/1 deletes the catering_booking" do
      catering_booking = catering_booking_fixture()
      assert {:ok, %CateringBooking{}} = Bookings.delete_catering_booking(catering_booking)
      assert_raise Ecto.NoResultsError, fn -> Bookings.get_catering_booking!(catering_booking.id) end
    end

    test "change_catering_booking/1 returns a catering_booking changeset" do
      catering_booking = catering_booking_fixture()
      assert %Ecto.Changeset{} = Bookings.change_catering_booking(catering_booking)
    end
  end
end

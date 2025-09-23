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

  describe "equipment_bookings" do
    alias Spato.Bookings.EquipmentBooking

    import Spato.BookingsFixtures

    @invalid_attrs %{status: nil, location: nil, requested_quantity: nil, usage_at: nil, return_at: nil, additional_notes: nil, condition_before: nil, condition_after: nil}

    test "list_equipment_bookings/0 returns all equipment_bookings" do
      equipment_booking = equipment_booking_fixture()
      assert Bookings.list_equipment_bookings() == [equipment_booking]
    end

    test "get_equipment_booking!/1 returns the equipment_booking with given id" do
      equipment_booking = equipment_booking_fixture()
      assert Bookings.get_equipment_booking!(equipment_booking.id) == equipment_booking
    end

    test "create_equipment_booking/1 with valid data creates a equipment_booking" do
      valid_attrs = %{status: "some status", location: "some location", requested_quantity: 42, usage_at: ~U[2025-09-22 09:02:00Z], return_at: ~U[2025-09-22 09:02:00Z], additional_notes: "some additional_notes", condition_before: "some condition_before", condition_after: "some condition_after"}

      assert {:ok, %EquipmentBooking{} = equipment_booking} = Bookings.create_equipment_booking(valid_attrs)
      assert equipment_booking.status == "some status"
      assert equipment_booking.location == "some location"
      assert equipment_booking.requested_quantity == 42
      assert equipment_booking.usage_at == ~U[2025-09-22 09:02:00Z]
      assert equipment_booking.return_at == ~U[2025-09-22 09:02:00Z]
      assert equipment_booking.additional_notes == "some additional_notes"
      assert equipment_booking.condition_before == "some condition_before"
      assert equipment_booking.condition_after == "some condition_after"
    end

    test "create_equipment_booking/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bookings.create_equipment_booking(@invalid_attrs)
    end

    test "update_equipment_booking/2 with valid data updates the equipment_booking" do
      equipment_booking = equipment_booking_fixture()
      update_attrs = %{status: "some updated status", location: "some updated location", requested_quantity: 43, usage_at: ~U[2025-09-23 09:02:00Z], return_at: ~U[2025-09-23 09:02:00Z], additional_notes: "some updated additional_notes", condition_before: "some updated condition_before", condition_after: "some updated condition_after"}

      assert {:ok, %EquipmentBooking{} = equipment_booking} = Bookings.update_equipment_booking(equipment_booking, update_attrs)
      assert equipment_booking.status == "some updated status"
      assert equipment_booking.location == "some updated location"
      assert equipment_booking.requested_quantity == 43
      assert equipment_booking.usage_at == ~U[2025-09-23 09:02:00Z]
      assert equipment_booking.return_at == ~U[2025-09-23 09:02:00Z]
      assert equipment_booking.additional_notes == "some updated additional_notes"
      assert equipment_booking.condition_before == "some updated condition_before"
      assert equipment_booking.condition_after == "some updated condition_after"
    end

    test "update_equipment_booking/2 with invalid data returns error changeset" do
      equipment_booking = equipment_booking_fixture()
      assert {:error, %Ecto.Changeset{}} = Bookings.update_equipment_booking(equipment_booking, @invalid_attrs)
      assert equipment_booking == Bookings.get_equipment_booking!(equipment_booking.id)
    end

    test "delete_equipment_booking/1 deletes the equipment_booking" do
      equipment_booking = equipment_booking_fixture()
      assert {:ok, %EquipmentBooking{}} = Bookings.delete_equipment_booking(equipment_booking)
      assert_raise Ecto.NoResultsError, fn -> Bookings.get_equipment_booking!(equipment_booking.id) end
    end

    test "change_equipment_booking/1 returns a equipment_booking changeset" do
      equipment_booking = equipment_booking_fixture()
      assert %Ecto.Changeset{} = Bookings.change_equipment_booking(equipment_booking)
    end
  end
end

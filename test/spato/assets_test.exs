defmodule Spato.AssetsTest do
  use Spato.DataCase

  alias Spato.Assets

  describe "vehicles" do
    alias Spato.Assets.Vehicle

    import Spato.AssetsFixtures

    @invalid_attrs %{name: nil, status: nil, type: nil, photo_url: nil, vehicle_model: nil, plate_number: nil}

    test "list_vehicles/0 returns all vehicles" do
      vehicle = vehicle_fixture()
      assert Assets.list_vehicles() == [vehicle]
    end

    test "get_vehicle!/1 returns the vehicle with given id" do
      vehicle = vehicle_fixture()
      assert Assets.get_vehicle!(vehicle.id) == vehicle
    end

    test "create_vehicle/1 with valid data creates a vehicle" do
      valid_attrs = %{name: "some name", status: "some status", type: "some type", photo_url: "some photo_url", vehicle_model: "some vehicle_model", plate_number: "some plate_number"}

      assert {:ok, %Vehicle{} = vehicle} = Assets.create_vehicle(valid_attrs)
      assert vehicle.name == "some name"
      assert vehicle.status == "some status"
      assert vehicle.type == "some type"
      assert vehicle.photo_url == "some photo_url"
      assert vehicle.vehicle_model == "some vehicle_model"
      assert vehicle.plate_number == "some plate_number"
    end

    test "create_vehicle/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assets.create_vehicle(@invalid_attrs)
    end

    test "update_vehicle/2 with valid data updates the vehicle" do
      vehicle = vehicle_fixture()
      update_attrs = %{name: "some updated name", status: "some updated status", type: "some updated type", photo_url: "some updated photo_url", vehicle_model: "some updated vehicle_model", plate_number: "some updated plate_number"}

      assert {:ok, %Vehicle{} = vehicle} = Assets.update_vehicle(vehicle, update_attrs)
      assert vehicle.name == "some updated name"
      assert vehicle.status == "some updated status"
      assert vehicle.type == "some updated type"
      assert vehicle.photo_url == "some updated photo_url"
      assert vehicle.vehicle_model == "some updated vehicle_model"
      assert vehicle.plate_number == "some updated plate_number"
    end

    test "update_vehicle/2 with invalid data returns error changeset" do
      vehicle = vehicle_fixture()
      assert {:error, %Ecto.Changeset{}} = Assets.update_vehicle(vehicle, @invalid_attrs)
      assert vehicle == Assets.get_vehicle!(vehicle.id)
    end

    test "delete_vehicle/1 deletes the vehicle" do
      vehicle = vehicle_fixture()
      assert {:ok, %Vehicle{}} = Assets.delete_vehicle(vehicle)
      assert_raise Ecto.NoResultsError, fn -> Assets.get_vehicle!(vehicle.id) end
    end

    test "change_vehicle/1 returns a vehicle changeset" do
      vehicle = vehicle_fixture()
      assert %Ecto.Changeset{} = Assets.change_vehicle(vehicle)
    end
  end
end

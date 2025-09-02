defmodule Spato.AssetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Spato.Assets` context.
  """

  @doc """
  Generate a vehicle.
  """
  def vehicle_fixture(attrs \\ %{}) do
    {:ok, vehicle} =
      attrs
      |> Enum.into(%{
        name: "some name",
        photo_url: "some photo_url",
        plate_number: "some plate_number",
        status: "some status",
        type: "some type",
        vehicle_model: "some vehicle_model"
      })
      |> Spato.Assets.create_vehicle()

    vehicle
  end

  @doc """
  Generate a equipment.
  """
  def equipment_fixture(attrs \\ %{}) do
    {:ok, equipment} =
      attrs
      |> Enum.into(%{
        name: "some name",
        photo_url: "some photo_url",
        quantity_available: 42,
        serial_number: "some serial_number",
        status: "some status",
        type: "some type"
      })
      |> Spato.Assets.create_equipment()

    equipment
  end
end

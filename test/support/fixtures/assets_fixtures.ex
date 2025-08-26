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
end

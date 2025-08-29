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
  Generate a meeting_room.
  """
  def meeting_room_fixture(attrs \\ %{}) do
    {:ok, meeting_room} =
      attrs
      |> Enum.into(%{
        available_facility: "some available_facility",
        capacity: 42,
        location: "some location",
        name: "some name",
        photo_url: "some photo_url",
        status: "some status"
      })
      |> Spato.Assets.create_meeting_room()

    meeting_room
  end
end

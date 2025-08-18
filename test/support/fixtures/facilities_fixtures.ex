defmodule Spato.FacilitiesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Spato.Facilities` context.
  """

  @doc """
  Generate a meeting_room.
  """
  def meeting_room_fixture(attrs \\ %{}) do
    {:ok, meeting_room} =
      attrs
      |> Enum.into(%{
        availability: "some availability",
        capacity: 42,
        features: "some features",
        image_url: "some image_url",
        location: "some location",
        name: "some name",
        status: "some status"
      })
      |> Spato.Facilities.create_meeting_room()

    meeting_room
  end
end

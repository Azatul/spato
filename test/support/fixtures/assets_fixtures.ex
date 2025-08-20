defmodule Spato.AssetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Spato.Assets` context.
  """

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

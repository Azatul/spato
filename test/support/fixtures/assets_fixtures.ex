defmodule Spato.AssetsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Spato.Assets` context.
  """

  @doc """
  Generate a catering_menu.
  """
  def catering_menu_fixture(attrs \\ %{}) do
    {:ok, catering_menu} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        photo_url: "some photo_url",
        price_per_head: "120.5",
        status: "some status",
        type: "some type"
      })
      |> Spato.Assets.create_catering_menu()

    catering_menu
  end
end

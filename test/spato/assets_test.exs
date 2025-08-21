defmodule Spato.AssetsTest do
  use Spato.DataCase

  alias Spato.Assets

  describe "catering_menus" do
    alias Spato.Assets.CateringMenu

    import Spato.AssetsFixtures

    @invalid_attrs %{name: nil, status: nil, type: nil, description: nil, price_per_head: nil, photo_url: nil}

    test "list_catering_menus/0 returns all catering_menus" do
      catering_menu = catering_menu_fixture()
      assert Assets.list_catering_menus() == [catering_menu]
    end

    test "get_catering_menu!/1 returns the catering_menu with given id" do
      catering_menu = catering_menu_fixture()
      assert Assets.get_catering_menu!(catering_menu.id) == catering_menu
    end

    test "create_catering_menu/1 with valid data creates a catering_menu" do
      valid_attrs = %{name: "some name", status: "some status", type: "some type", description: "some description", price_per_head: "120.5", photo_url: "some photo_url"}

      assert {:ok, %CateringMenu{} = catering_menu} = Assets.create_catering_menu(valid_attrs)
      assert catering_menu.name == "some name"
      assert catering_menu.status == "some status"
      assert catering_menu.type == "some type"
      assert catering_menu.description == "some description"
      assert catering_menu.price_per_head == Decimal.new("120.5")
      assert catering_menu.photo_url == "some photo_url"
    end

    test "create_catering_menu/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assets.create_catering_menu(@invalid_attrs)
    end

    test "update_catering_menu/2 with valid data updates the catering_menu" do
      catering_menu = catering_menu_fixture()
      update_attrs = %{name: "some updated name", status: "some updated status", type: "some updated type", description: "some updated description", price_per_head: "456.7", photo_url: "some updated photo_url"}

      assert {:ok, %CateringMenu{} = catering_menu} = Assets.update_catering_menu(catering_menu, update_attrs)
      assert catering_menu.name == "some updated name"
      assert catering_menu.status == "some updated status"
      assert catering_menu.type == "some updated type"
      assert catering_menu.description == "some updated description"
      assert catering_menu.price_per_head == Decimal.new("456.7")
      assert catering_menu.photo_url == "some updated photo_url"
    end

    test "update_catering_menu/2 with invalid data returns error changeset" do
      catering_menu = catering_menu_fixture()
      assert {:error, %Ecto.Changeset{}} = Assets.update_catering_menu(catering_menu, @invalid_attrs)
      assert catering_menu == Assets.get_catering_menu!(catering_menu.id)
    end

    test "delete_catering_menu/1 deletes the catering_menu" do
      catering_menu = catering_menu_fixture()
      assert {:ok, %CateringMenu{}} = Assets.delete_catering_menu(catering_menu)
      assert_raise Ecto.NoResultsError, fn -> Assets.get_catering_menu!(catering_menu.id) end
    end

    test "change_catering_menu/1 returns a catering_menu changeset" do
      catering_menu = catering_menu_fixture()
      assert %Ecto.Changeset{} = Assets.change_catering_menu(catering_menu)
    end
  end
end

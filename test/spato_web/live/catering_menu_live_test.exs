defmodule SpatoWeb.CateringMenuLiveTest do
  use SpatoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Spato.AssetsFixtures

  @create_attrs %{name: "some name", status: "some status", type: "some type", description: "some description", price_per_head: "120.5", photo_url: "some photo_url"}
  @update_attrs %{name: "some updated name", status: "some updated status", type: "some updated type", description: "some updated description", price_per_head: "456.7", photo_url: "some updated photo_url"}
  @invalid_attrs %{name: nil, status: nil, type: nil, description: nil, price_per_head: nil, photo_url: nil}

  defp create_catering_menu(_) do
    catering_menu = catering_menu_fixture()
    %{catering_menu: catering_menu}
  end

  describe "Index" do
    setup [:create_catering_menu]

    test "lists all catering_menus", %{conn: conn, catering_menu: catering_menu} do
      {:ok, _index_live, html} = live(conn, ~p"/catering_menus")

      assert html =~ "Listing Catering menus"
      assert html =~ catering_menu.name
    end

    test "saves new catering_menu", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/catering_menus")

      assert index_live |> element("a", "New Catering menu") |> render_click() =~
               "New Catering menu"

      assert_patch(index_live, ~p"/catering_menus/new")

      assert index_live
             |> form("#catering_menu-form", catering_menu: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#catering_menu-form", catering_menu: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/catering_menus")

      html = render(index_live)
      assert html =~ "Catering menu created successfully"
      assert html =~ "some name"
    end

    test "updates catering_menu in listing", %{conn: conn, catering_menu: catering_menu} do
      {:ok, index_live, _html} = live(conn, ~p"/catering_menus")

      assert index_live |> element("#catering_menus-#{catering_menu.id} a", "Edit") |> render_click() =~
               "Edit Catering menu"

      assert_patch(index_live, ~p"/catering_menus/#{catering_menu}/edit")

      assert index_live
             |> form("#catering_menu-form", catering_menu: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#catering_menu-form", catering_menu: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/catering_menus")

      html = render(index_live)
      assert html =~ "Catering menu updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes catering_menu in listing", %{conn: conn, catering_menu: catering_menu} do
      {:ok, index_live, _html} = live(conn, ~p"/catering_menus")

      assert index_live |> element("#catering_menus-#{catering_menu.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#catering_menus-#{catering_menu.id}")
    end
  end

  describe "Show" do
    setup [:create_catering_menu]

    test "displays catering_menu", %{conn: conn, catering_menu: catering_menu} do
      {:ok, _show_live, html} = live(conn, ~p"/catering_menus/#{catering_menu}")

      assert html =~ "Show Catering menu"
      assert html =~ catering_menu.name
    end

    test "updates catering_menu within modal", %{conn: conn, catering_menu: catering_menu} do
      {:ok, show_live, _html} = live(conn, ~p"/catering_menus/#{catering_menu}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Catering menu"

      assert_patch(show_live, ~p"/catering_menus/#{catering_menu}/show/edit")

      assert show_live
             |> form("#catering_menu-form", catering_menu: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#catering_menu-form", catering_menu: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/catering_menus/#{catering_menu}")

      html = render(show_live)
      assert html =~ "Catering menu updated successfully"
      assert html =~ "some updated name"
    end
  end
end

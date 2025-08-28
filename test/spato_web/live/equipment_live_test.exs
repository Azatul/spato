defmodule SpatoWeb.EquipmentLiveTest do
  use SpatoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Spato.AssetsFixtures

  @create_attrs %{name: "some name", status: "some status", type: "some type", photo_url: "some photo_url", serial_number: "some serial_number", quantity_available: 42}
  @update_attrs %{name: "some updated name", status: "some updated status", type: "some updated type", photo_url: "some updated photo_url", serial_number: "some updated serial_number", quantity_available: 43}
  @invalid_attrs %{name: nil, status: nil, type: nil, photo_url: nil, serial_number: nil, quantity_available: nil}

  defp create_equipment(_) do
    equipment = equipment_fixture()
    %{equipment: equipment}
  end

  describe "Index" do
    setup [:create_equipment]

    test "lists all equipments", %{conn: conn, equipment: equipment} do
      {:ok, _index_live, html} = live(conn, ~p"/equipments")

      assert html =~ "Listing Equipments"
      assert html =~ equipment.name
    end

    test "saves new equipment", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/equipments")

      assert index_live |> element("a", "New Equipment") |> render_click() =~
               "New Equipment"

      assert_patch(index_live, ~p"/equipments/new")

      assert index_live
             |> form("#equipment-form", equipment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#equipment-form", equipment: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/equipments")

      html = render(index_live)
      assert html =~ "Equipment created successfully"
      assert html =~ "some name"
    end

    test "updates equipment in listing", %{conn: conn, equipment: equipment} do
      {:ok, index_live, _html} = live(conn, ~p"/equipments")

      assert index_live |> element("#equipments-#{equipment.id} a", "Edit") |> render_click() =~
               "Edit Equipment"

      assert_patch(index_live, ~p"/equipments/#{equipment}/edit")

      assert index_live
             |> form("#equipment-form", equipment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#equipment-form", equipment: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/equipments")

      html = render(index_live)
      assert html =~ "Equipment updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes equipment in listing", %{conn: conn, equipment: equipment} do
      {:ok, index_live, _html} = live(conn, ~p"/equipments")

      assert index_live |> element("#equipments-#{equipment.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#equipments-#{equipment.id}")
    end
  end

  describe "Show" do
    setup [:create_equipment]

    test "displays equipment", %{conn: conn, equipment: equipment} do
      {:ok, _show_live, html} = live(conn, ~p"/equipments/#{equipment}")

      assert html =~ "Show Equipment"
      assert html =~ equipment.name
    end

    test "updates equipment within modal", %{conn: conn, equipment: equipment} do
      {:ok, show_live, _html} = live(conn, ~p"/equipments/#{equipment}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Equipment"

      assert_patch(show_live, ~p"/equipments/#{equipment}/show/edit")

      assert show_live
             |> form("#equipment-form", equipment: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#equipment-form", equipment: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/equipments/#{equipment}")

      html = render(show_live)
      assert html =~ "Equipment updated successfully"
      assert html =~ "some updated name"
    end
  end
end

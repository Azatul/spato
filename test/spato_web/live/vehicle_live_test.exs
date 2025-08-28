defmodule SpatoWeb.VehicleLiveTest do
  use SpatoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Spato.AssetsFixtures

  @create_attrs %{name: "some name", status: "some status", type: "some type", photo_url: "some photo_url", vehicle_model: "some vehicle_model", plate_number: "some plate_number"}
  @update_attrs %{name: "some updated name", status: "some updated status", type: "some updated type", photo_url: "some updated photo_url", vehicle_model: "some updated vehicle_model", plate_number: "some updated plate_number"}
  @invalid_attrs %{name: nil, status: nil, type: nil, photo_url: nil, vehicle_model: nil, plate_number: nil}

  defp create_vehicle(_) do
    vehicle = vehicle_fixture()
    %{vehicle: vehicle}
  end

  describe "Index" do
    setup [:create_vehicle]

    test "lists all vehicles", %{conn: conn, vehicle: vehicle} do
      {:ok, _index_live, html} = live(conn, ~p"/vehicles")

      assert html =~ "Senarai Kenderaan"
      assert html =~ vehicle.name
    end

    test "saves new vehicle", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/vehicles")

      assert index_live |> element("a", "Kenderaan Baru") |> render_click() =~
               "Kenderaan Baru"

      assert_patch(index_live, ~p"/vehicles/new")

      assert index_live
             |> form("#vehicle-form", vehicle: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#vehicle-form", vehicle: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/vehicles")

      html = render(index_live)
      assert html =~ "Kenderaan berjaya dicipta"
      assert html =~ "some name"
    end

    test "updates vehicle in listing", %{conn: conn, vehicle: vehicle} do
      {:ok, index_live, _html} = live(conn, ~p"/vehicles")

      assert index_live |> element("#vehicles-#{vehicle.id} a", "Edit") |> render_click() =~
               "Kemaskini Kenderaan"

      assert_patch(index_live, ~p"/vehicles/#{vehicle}/edit")

      assert index_live
             |> form("#vehicle-form", vehicle: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#vehicle-form", vehicle: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/vehicles")

      html = render(index_live)
      assert html =~ "Kenderaan berjaya dikemaskini"
      assert html =~ "some updated name"
    end

    test "deletes vehicle in listing", %{conn: conn, vehicle: vehicle} do
      {:ok, index_live, _html} = live(conn, ~p"/vehicles")

      assert index_live |> element("#vehicles-#{vehicle.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#vehicles-#{vehicle.id}")
    end
  end

  describe "Show" do
    setup [:create_vehicle]

    test "displays vehicle", %{conn: conn, vehicle: vehicle} do
      {:ok, _show_live, html} = live(conn, ~p"/vehicles/#{vehicle}")

      assert html =~ "Lihat Kenderaan"
      assert html =~ vehicle.name
    end

    test "updates vehicle within modal", %{conn: conn, vehicle: vehicle} do
      {:ok, show_live, _html} = live(conn, ~p"/vehicles/#{vehicle}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Kemaskini Kenderaan"

      assert_patch(show_live, ~p"/vehicles/#{vehicle}/show/edit")

      assert show_live
             |> form("#vehicle-form", vehicle: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#vehicle-form", vehicle: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/vehicles/#{vehicle}")

      html = render(show_live)
      assert html =~ "Kenderaan berjaya dikemaskini"
      assert html =~ "some updated name"
    end
  end
end

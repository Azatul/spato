defmodule SpatoWeb.VehicleBookingLiveTest do
  use SpatoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Spato.BookingsFixtures

  @create_attrs %{status: "some status", purpose: "some purpose", trip_destination: "some trip_destination", pickup_time: "2025-09-03T12:57:00", return_time: "2025-09-03T12:57:00", additional_notes: "some additional_notes", rejection_reason: "some rejection_reason"}
  @update_attrs %{status: "some updated status", purpose: "some updated purpose", trip_destination: "some updated trip_destination", pickup_time: "2025-09-04T12:57:00", return_time: "2025-09-04T12:57:00", additional_notes: "some updated additional_notes", rejection_reason: "some updated rejection_reason"}
  @invalid_attrs %{status: nil, purpose: nil, trip_destination: nil, pickup_time: nil, return_time: nil, additional_notes: nil, rejection_reason: nil}

  defp create_vehicle_booking(_) do
    vehicle_booking = vehicle_booking_fixture()
    %{vehicle_booking: vehicle_booking}
  end

  describe "Index" do
    setup [:create_vehicle_booking]

    test "lists all vehicle_bookings", %{conn: conn, vehicle_booking: vehicle_booking} do
      {:ok, _index_live, html} = live(conn, ~p"/vehicle_bookings")

      assert html =~ "Listing Vehicle bookings"
      assert html =~ vehicle_booking.status
    end

    test "saves new vehicle_booking", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/vehicle_bookings")

      assert index_live |> element("a", "New Vehicle booking") |> render_click() =~
               "New Vehicle booking"

      assert_patch(index_live, ~p"/vehicle_bookings/new")

      assert index_live
             |> form("#vehicle_booking-form", vehicle_booking: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#vehicle_booking-form", vehicle_booking: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/vehicle_bookings")

      html = render(index_live)
      assert html =~ "Vehicle booking created successfully"
      assert html =~ "some status"
    end

    test "updates vehicle_booking in listing", %{conn: conn, vehicle_booking: vehicle_booking} do
      {:ok, index_live, _html} = live(conn, ~p"/vehicle_bookings")

      assert index_live |> element("#vehicle_bookings-#{vehicle_booking.id} a", "Edit") |> render_click() =~
               "Edit Vehicle booking"

      assert_patch(index_live, ~p"/vehicle_bookings/#{vehicle_booking}/edit")

      assert index_live
             |> form("#vehicle_booking-form", vehicle_booking: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#vehicle_booking-form", vehicle_booking: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/vehicle_bookings")

      html = render(index_live)
      assert html =~ "Vehicle booking updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes vehicle_booking in listing", %{conn: conn, vehicle_booking: vehicle_booking} do
      {:ok, index_live, _html} = live(conn, ~p"/vehicle_bookings")

      assert index_live |> element("#vehicle_bookings-#{vehicle_booking.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#vehicle_bookings-#{vehicle_booking.id}")
    end
  end

  describe "Show" do
    setup [:create_vehicle_booking]

    test "displays vehicle_booking", %{conn: conn, vehicle_booking: vehicle_booking} do
      {:ok, _show_live, html} = live(conn, ~p"/vehicle_bookings/#{vehicle_booking}")

      assert html =~ "Show Vehicle booking"
      assert html =~ vehicle_booking.status
    end

    test "updates vehicle_booking within modal", %{conn: conn, vehicle_booking: vehicle_booking} do
      {:ok, show_live, _html} = live(conn, ~p"/vehicle_bookings/#{vehicle_booking}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Vehicle booking"

      assert_patch(show_live, ~p"/vehicle_bookings/#{vehicle_booking}/show/edit")

      assert show_live
             |> form("#vehicle_booking-form", vehicle_booking: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#vehicle_booking-form", vehicle_booking: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/vehicle_bookings/#{vehicle_booking}")

      html = render(show_live)
      assert html =~ "Vehicle booking updated successfully"
      assert html =~ "some updated status"
    end
  end
end

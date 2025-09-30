defmodule SpatoWeb.CateringBookingLiveTest do
  use SpatoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Spato.BookingsFixtures

  @create_attrs %{status: "some status", date: "2025-09-21", time: "14:00", location: "some location", participants: 42, total_cost: "120.5", special_request: "some special_request"}
  @update_attrs %{status: "some updated status", date: "2025-09-22", time: "15:01", location: "some updated location", participants: 43, total_cost: "456.7", special_request: "some updated special_request"}
  @invalid_attrs %{status: nil, date: nil, time: nil, location: nil, participants: nil, total_cost: nil, special_request: nil}

  defp create_catering_booking(_) do
    catering_booking = catering_booking_fixture()
    %{catering_booking: catering_booking}
  end

  describe "Index" do
    setup [:create_catering_booking]

    test "lists all catering_bookings", %{conn: conn, catering_booking: catering_booking} do
      {:ok, _index_live, html} = live(conn, ~p"/catering_bookings")

      assert html =~ "Listing Catering bookings"
      assert html =~ catering_booking.status
    end

    test "saves new catering_booking", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/catering_bookings")

      assert index_live |> element("a", "New Catering booking") |> render_click() =~
               "New Catering booking"

      assert_patch(index_live, ~p"/catering_bookings/new")

      assert index_live
             |> form("#catering_booking-form", catering_booking: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#catering_booking-form", catering_booking: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/catering_bookings")

      html = render(index_live)
      assert html =~ "Catering booking created successfully"
      assert html =~ "some status"
    end

    test "updates catering_booking in listing", %{conn: conn, catering_booking: catering_booking} do
      {:ok, index_live, _html} = live(conn, ~p"/catering_bookings")

      assert index_live |> element("#catering_bookings-#{catering_booking.id} a", "Edit") |> render_click() =~
               "Edit Catering booking"

      assert_patch(index_live, ~p"/catering_bookings/#{catering_booking}/edit")

      assert index_live
             |> form("#catering_booking-form", catering_booking: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#catering_booking-form", catering_booking: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/catering_bookings")

      html = render(index_live)
      assert html =~ "Catering booking updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes catering_booking in listing", %{conn: conn, catering_booking: catering_booking} do
      {:ok, index_live, _html} = live(conn, ~p"/catering_bookings")

      assert index_live |> element("#catering_bookings-#{catering_booking.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#catering_bookings-#{catering_booking.id}")
    end
  end

  describe "Show" do
    setup [:create_catering_booking]

    test "displays catering_booking", %{conn: conn, catering_booking: catering_booking} do
      {:ok, _show_live, html} = live(conn, ~p"/catering_bookings/#{catering_booking}")

      assert html =~ "Show Catering booking"
      assert html =~ catering_booking.status
    end

    test "updates catering_booking within modal", %{conn: conn, catering_booking: catering_booking} do
      {:ok, show_live, _html} = live(conn, ~p"/catering_bookings/#{catering_booking}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Catering booking"

      assert_patch(show_live, ~p"/catering_bookings/#{catering_booking}/show/edit")

      assert show_live
             |> form("#catering_booking-form", catering_booking: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#catering_booking-form", catering_booking: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/catering_bookings/#{catering_booking}")

      html = render(show_live)
      assert html =~ "Catering booking updated successfully"
      assert html =~ "some updated status"
    end
  end
end

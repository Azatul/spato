defmodule SpatoWeb.EquipmentBookingLiveTest do
  use SpatoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Spato.BookingsFixtures

  @create_attrs %{status: "some status", location: "some location", quantity: 42, usage_date: "2025-09-16", return_date: "2025-09-16", usage_time: "14:00", return_time: "14:00", additional_notes: "some additional_notes", condition_before: "some condition_before", condition_after: "some condition_after"}
  @update_attrs %{status: "some updated status", location: "some updated location", quantity: 43, usage_date: "2025-09-17", return_date: "2025-09-17", usage_time: "15:01", return_time: "15:01", additional_notes: "some updated additional_notes", condition_before: "some updated condition_before", condition_after: "some updated condition_after"}
  @invalid_attrs %{status: nil, location: nil, quantity: nil, usage_date: nil, return_date: nil, usage_time: nil, return_time: nil, additional_notes: nil, condition_before: nil, condition_after: nil}

  defp create_equipment_booking(_) do
    equipment_booking = equipment_booking_fixture()
    %{equipment_booking: equipment_booking}
  end

  describe "Index" do
    setup [:create_equipment_booking]

    test "lists all equipment_bookings", %{conn: conn, equipment_booking: equipment_booking} do
      {:ok, _index_live, html} = live(conn, ~p"/equipment_bookings")

      assert html =~ "Listing Equipment bookings"
      assert html =~ equipment_booking.status
    end

    test "saves new equipment_booking", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/equipment_bookings")

      assert index_live |> element("a", "New Equipment booking") |> render_click() =~
               "New Equipment booking"

      assert_patch(index_live, ~p"/equipment_bookings/new")

      assert index_live
             |> form("#equipment_booking-form", equipment_booking: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#equipment_booking-form", equipment_booking: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/equipment_bookings")

      html = render(index_live)
      assert html =~ "Equipment booking created successfully"
      assert html =~ "some status"
    end

    test "updates equipment_booking in listing", %{conn: conn, equipment_booking: equipment_booking} do
      {:ok, index_live, _html} = live(conn, ~p"/equipment_bookings")

      assert index_live |> element("#equipment_bookings-#{equipment_booking.id} a", "Edit") |> render_click() =~
               "Edit Equipment booking"

      assert_patch(index_live, ~p"/equipment_bookings/#{equipment_booking}/edit")

      assert index_live
             |> form("#equipment_booking-form", equipment_booking: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#equipment_booking-form", equipment_booking: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/equipment_bookings")

      html = render(index_live)
      assert html =~ "Equipment booking updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes equipment_booking in listing", %{conn: conn, equipment_booking: equipment_booking} do
      {:ok, index_live, _html} = live(conn, ~p"/equipment_bookings")

      assert index_live |> element("#equipment_bookings-#{equipment_booking.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#equipment_bookings-#{equipment_booking.id}")
    end
  end

  describe "Show" do
    setup [:create_equipment_booking]

    test "displays equipment_booking", %{conn: conn, equipment_booking: equipment_booking} do
      {:ok, _show_live, html} = live(conn, ~p"/equipment_bookings/#{equipment_booking}")

      assert html =~ "Show Equipment booking"
      assert html =~ equipment_booking.status
    end

    test "updates equipment_booking within modal", %{conn: conn, equipment_booking: equipment_booking} do
      {:ok, show_live, _html} = live(conn, ~p"/equipment_bookings/#{equipment_booking}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Equipment booking"

      assert_patch(show_live, ~p"/equipment_bookings/#{equipment_booking}/show/edit")

      assert show_live
             |> form("#equipment_booking-form", equipment_booking: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#equipment_booking-form", equipment_booking: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/equipment_bookings/#{equipment_booking}")

      html = render(show_live)
      assert html =~ "Equipment booking updated successfully"
      assert html =~ "some updated status"
    end
  end
end

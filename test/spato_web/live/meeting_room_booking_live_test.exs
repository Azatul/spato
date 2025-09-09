defmodule SpatoWeb.MeetingRoomBookingLiveTest do
  use SpatoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Spato.BookingsFixtures

  @create_attrs %{status: "some status", purpose: "some purpose", participants: 42, start_time: "2025-09-08T11:41:00", end_time: "2025-09-08T11:41:00", is_recurring: true, recurrence_pattern: "some recurrence_pattern", notes: "some notes"}
  @update_attrs %{status: "some updated status", purpose: "some updated purpose", participants: 43, start_time: "2025-09-09T11:41:00", end_time: "2025-09-09T11:41:00", is_recurring: false, recurrence_pattern: "some updated recurrence_pattern", notes: "some updated notes"}
  @invalid_attrs %{status: nil, purpose: nil, participants: nil, start_time: nil, end_time: nil, is_recurring: false, recurrence_pattern: nil, notes: nil}

  defp create_meeting_room_booking(_) do
    meeting_room_booking = meeting_room_booking_fixture()
    %{meeting_room_booking: meeting_room_booking}
  end

  describe "Index" do
    setup [:create_meeting_room_booking]

    test "lists all meeting_room_bookings", %{conn: conn, meeting_room_booking: meeting_room_booking} do
      {:ok, _index_live, html} = live(conn, ~p"/meeting_room_bookings")

      assert html =~ "Listing Meeting room bookings"
      assert html =~ meeting_room_booking.status
    end

    test "saves new meeting_room_booking", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/meeting_room_bookings")

      assert index_live |> element("a", "New Meeting room booking") |> render_click() =~
               "New Meeting room booking"

      assert_patch(index_live, ~p"/meeting_room_bookings/new")

      assert index_live
             |> form("#meeting_room_booking-form", meeting_room_booking: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#meeting_room_booking-form", meeting_room_booking: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/meeting_room_bookings")

      html = render(index_live)
      assert html =~ "Meeting room booking created successfully"
      assert html =~ "some status"
    end

    test "updates meeting_room_booking in listing", %{conn: conn, meeting_room_booking: meeting_room_booking} do
      {:ok, index_live, _html} = live(conn, ~p"/meeting_room_bookings")

      assert index_live |> element("#meeting_room_bookings-#{meeting_room_booking.id} a", "Edit") |> render_click() =~
               "Edit Meeting room booking"

      assert_patch(index_live, ~p"/meeting_room_bookings/#{meeting_room_booking}/edit")

      assert index_live
             |> form("#meeting_room_booking-form", meeting_room_booking: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#meeting_room_booking-form", meeting_room_booking: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/meeting_room_bookings")

      html = render(index_live)
      assert html =~ "Meeting room booking updated successfully"
      assert html =~ "some updated status"
    end

    test "deletes meeting_room_booking in listing", %{conn: conn, meeting_room_booking: meeting_room_booking} do
      {:ok, index_live, _html} = live(conn, ~p"/meeting_room_bookings")

      assert index_live |> element("#meeting_room_bookings-#{meeting_room_booking.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#meeting_room_bookings-#{meeting_room_booking.id}")
    end
  end

  describe "Show" do
    setup [:create_meeting_room_booking]

    test "displays meeting_room_booking", %{conn: conn, meeting_room_booking: meeting_room_booking} do
      {:ok, _show_live, html} = live(conn, ~p"/meeting_room_bookings/#{meeting_room_booking}")

      assert html =~ "Show Meeting room booking"
      assert html =~ meeting_room_booking.status
    end

    test "updates meeting_room_booking within modal", %{conn: conn, meeting_room_booking: meeting_room_booking} do
      {:ok, show_live, _html} = live(conn, ~p"/meeting_room_bookings/#{meeting_room_booking}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Meeting room booking"

      assert_patch(show_live, ~p"/meeting_room_bookings/#{meeting_room_booking}/show/edit")

      assert show_live
             |> form("#meeting_room_booking-form", meeting_room_booking: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#meeting_room_booking-form", meeting_room_booking: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/meeting_room_bookings/#{meeting_room_booking}")

      html = render(show_live)
      assert html =~ "Meeting room booking updated successfully"
      assert html =~ "some updated status"
    end
  end
end

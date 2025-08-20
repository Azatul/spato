defmodule SpatoWeb.MeetingRoomLiveTest do
  use SpatoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Spato.AssetsFixtures

  @create_attrs %{name: "some name", status: "some status", location: "some location", capacity: 42, available_facility: "some available_facility", photo_url: "some photo_url"}
  @update_attrs %{name: "some updated name", status: "some updated status", location: "some updated location", capacity: 43, available_facility: "some updated available_facility", photo_url: "some updated photo_url"}
  @invalid_attrs %{name: nil, status: nil, location: nil, capacity: nil, available_facility: nil, photo_url: nil}

  defp create_meeting_room(_) do
    meeting_room = meeting_room_fixture()
    %{meeting_room: meeting_room}
  end

  describe "Index" do
    setup [:create_meeting_room]

    test "lists all meeting_rooms", %{conn: conn, meeting_room: meeting_room} do
      {:ok, _index_live, html} = live(conn, ~p"/meeting_rooms")

      assert html =~ "Listing Meeting rooms"
      assert html =~ meeting_room.name
    end

    test "saves new meeting_room", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/meeting_rooms")

      assert index_live |> element("a", "New Meeting room") |> render_click() =~
               "New Meeting room"

      assert_patch(index_live, ~p"/meeting_rooms/new")

      assert index_live
             |> form("#meeting_room-form", meeting_room: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#meeting_room-form", meeting_room: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/meeting_rooms")

      html = render(index_live)
      assert html =~ "Meeting room created successfully"
      assert html =~ "some name"
    end

    test "updates meeting_room in listing", %{conn: conn, meeting_room: meeting_room} do
      {:ok, index_live, _html} = live(conn, ~p"/meeting_rooms")

      assert index_live |> element("#meeting_rooms-#{meeting_room.id} a", "Edit") |> render_click() =~
               "Edit Meeting room"

      assert_patch(index_live, ~p"/meeting_rooms/#{meeting_room}/edit")

      assert index_live
             |> form("#meeting_room-form", meeting_room: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#meeting_room-form", meeting_room: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/meeting_rooms")

      html = render(index_live)
      assert html =~ "Meeting room updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes meeting_room in listing", %{conn: conn, meeting_room: meeting_room} do
      {:ok, index_live, _html} = live(conn, ~p"/meeting_rooms")

      assert index_live |> element("#meeting_rooms-#{meeting_room.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#meeting_rooms-#{meeting_room.id}")
    end
  end

  describe "Show" do
    setup [:create_meeting_room]

    test "displays meeting_room", %{conn: conn, meeting_room: meeting_room} do
      {:ok, _show_live, html} = live(conn, ~p"/meeting_rooms/#{meeting_room}")

      assert html =~ "Show Meeting room"
      assert html =~ meeting_room.name
    end

    test "updates meeting_room within modal", %{conn: conn, meeting_room: meeting_room} do
      {:ok, show_live, _html} = live(conn, ~p"/meeting_rooms/#{meeting_room}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Meeting room"

      assert_patch(show_live, ~p"/meeting_rooms/#{meeting_room}/show/edit")

      assert show_live
             |> form("#meeting_room-form", meeting_room: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#meeting_room-form", meeting_room: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/meeting_rooms/#{meeting_room}")

      html = render(show_live)
      assert html =~ "Meeting room updated successfully"
      assert html =~ "some updated name"
    end
  end
end

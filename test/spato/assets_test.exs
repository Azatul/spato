defmodule Spato.AssetsTest do
  use Spato.DataCase

  alias Spato.Assets

  describe "meeting_rooms" do
    alias Spato.Assets.MeetingRoom

    import Spato.AssetsFixtures

    @invalid_attrs %{name: nil, status: nil, location: nil, capacity: nil, available_facility: nil, photo_url: nil}

    test "list_meeting_rooms/0 returns all meeting_rooms" do
      meeting_room = meeting_room_fixture()
      assert Assets.list_meeting_rooms() == [meeting_room]
    end

    test "get_meeting_room!/1 returns the meeting_room with given id" do
      meeting_room = meeting_room_fixture()
      assert Assets.get_meeting_room!(meeting_room.id) == meeting_room
    end

    test "create_meeting_room/1 with valid data creates a meeting_room" do
      valid_attrs = %{name: "some name", status: "some status", location: "some location", capacity: 42, available_facility: "some available_facility", photo_url: "some photo_url"}

      assert {:ok, %MeetingRoom{} = meeting_room} = Assets.create_meeting_room(valid_attrs)
      assert meeting_room.name == "some name"
      assert meeting_room.status == "some status"
      assert meeting_room.location == "some location"
      assert meeting_room.capacity == 42
      assert meeting_room.available_facility == "some available_facility"
      assert meeting_room.photo_url == "some photo_url"
    end

    test "create_meeting_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Assets.create_meeting_room(@invalid_attrs)
    end

    test "update_meeting_room/2 with valid data updates the meeting_room" do
      meeting_room = meeting_room_fixture()
      update_attrs = %{name: "some updated name", status: "some updated status", location: "some updated location", capacity: 43, available_facility: "some updated available_facility", photo_url: "some updated photo_url"}

      assert {:ok, %MeetingRoom{} = meeting_room} = Assets.update_meeting_room(meeting_room, update_attrs)
      assert meeting_room.name == "some updated name"
      assert meeting_room.status == "some updated status"
      assert meeting_room.location == "some updated location"
      assert meeting_room.capacity == 43
      assert meeting_room.available_facility == "some updated available_facility"
      assert meeting_room.photo_url == "some updated photo_url"
    end

    test "update_meeting_room/2 with invalid data returns error changeset" do
      meeting_room = meeting_room_fixture()
      assert {:error, %Ecto.Changeset{}} = Assets.update_meeting_room(meeting_room, @invalid_attrs)
      assert meeting_room == Assets.get_meeting_room!(meeting_room.id)
    end

    test "delete_meeting_room/1 deletes the meeting_room" do
      meeting_room = meeting_room_fixture()
      assert {:ok, %MeetingRoom{}} = Assets.delete_meeting_room(meeting_room)
      assert_raise Ecto.NoResultsError, fn -> Assets.get_meeting_room!(meeting_room.id) end
    end

    test "change_meeting_room/1 returns a meeting_room changeset" do
      meeting_room = meeting_room_fixture()
      assert %Ecto.Changeset{} = Assets.change_meeting_room(meeting_room)
    end
  end
end

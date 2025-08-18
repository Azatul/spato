defmodule SpatoWeb.MeetingRoomLive.Index do
  use SpatoWeb, :live_view

  alias Spato.Facilities
  alias Spato.Facilities.MeetingRoom

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :meeting_rooms, Facilities.list_meeting_rooms())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Meeting room")
    |> assign(:meeting_room, Facilities.get_meeting_room!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Meeting room")
    |> assign(:meeting_room, %MeetingRoom{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Meeting rooms")
    |> assign(:meeting_room, nil)
  end

  @impl true
  def handle_info({SpatoWeb.MeetingRoomLive.FormComponent, {:saved, meeting_room}}, socket) do
    {:noreply, stream_insert(socket, :meeting_rooms, meeting_room)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    meeting_room = Facilities.get_meeting_room!(id)
    {:ok, _} = Facilities.delete_meeting_room(meeting_room)

    {:noreply, stream_delete(socket, :meeting_rooms, meeting_room)}
  end
end

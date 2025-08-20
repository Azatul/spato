defmodule SpatoWeb.MeetingRoomLive.Index do
  use SpatoWeb, :live_view

  alias Spato.Assets
  alias Spato.Assets.MeetingRoom

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :meeting_rooms, Assets.list_meeting_rooms())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Meeting room")
    |> assign(:meeting_room, Assets.get_meeting_room!(id))
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
    meeting_room = Assets.get_meeting_room!(id)
    {:ok, _} = Assets.delete_meeting_room(meeting_room)

    {:noreply, stream_delete(socket, :meeting_rooms, meeting_room)}
  end

@impl true
def render(assigns) do
  ~H"""
<.header>
  Listing Meeting rooms
  <:actions>
    <.link patch={~p"/meeting_rooms/new"}>
      <.button>New Meeting room</.button>
    </.link>
  </:actions>
</.header>

<.table
  id="meeting_rooms"
  rows={@streams.meeting_rooms}
  row_click={fn {_id, meeting_room} -> JS.navigate(~p"/meeting_rooms/#{meeting_room}") end}
>
  <:col :let={{_id, meeting_room}} label="Name">{meeting_room.name}</:col>
  <:col :let={{_id, meeting_room}} label="Location">{meeting_room.location}</:col>
  <:col :let={{_id, meeting_room}} label="Capacity">{meeting_room.capacity}</:col>
  <:col :let={{_id, meeting_room}} label="Available facility">{meeting_room.available_facility}</:col>
  <:col :let={{_id, meeting_room}} label="Photo url">{meeting_room.photo_url}</:col>
  <:col :let={{_id, meeting_room}} label="Status">{meeting_room.status}</:col>
  <:action :let={{_id, meeting_room}}>
    <div class="sr-only">
      <.link navigate={~p"/meeting_rooms/#{meeting_room}"}>Show</.link>
    </div>
    <.link patch={~p"/meeting_rooms/#{meeting_room}/edit"}>Edit</.link>
  </:action>
  <:action :let={{id, meeting_room}}>
    <.link
      phx-click={JS.push("delete", value: %{id: meeting_room.id}) |> hide("##{id}")}
      data-confirm="Are you sure?"
    >
      Delete
    </.link>
  </:action>
</.table>

<.modal :if={@live_action in [:new, :edit]} id="meeting_room-modal" show on_cancel={JS.patch(~p"/meeting_rooms")}>
  <.live_component
    module={SpatoWeb.MeetingRoomLive.FormComponent}
    id={@meeting_room.id || :new}
    title={@page_title}
    action={@live_action}
    meeting_room={@meeting_room}
    patch={~p"/meeting_rooms"}
  />
</.modal>
  """
  end
end

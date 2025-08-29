defmodule SpatoWeb.MeetingRoomLive.Show do
  use SpatoWeb, :live_view

  alias Spato.Assets

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:meeting_room, Assets.get_meeting_room!(id))}
  end

  defp page_title(:show), do: "Show Meeting room"
  defp page_title(:edit), do: "Edit Meeting room"


@impl true
def render(assigns) do
  ~H"""
  <.header>
    Meeting room <%= @meeting_room.id %>
    <:subtitle>This is a meeting_room record from your database.</:subtitle>
    <:actions>
      <.link patch={~p"/admin/meeting_rooms/#{@meeting_room}/show/edit"} phx-click={JS.push_focus()}>
        <.button>Edit meeting_room</.button>
      </.link>
    </:actions>
  </.header>

  <.list>
    <:item title="Name">{@meeting_room.name}</:item>
  <:item title="Location">{@meeting_room.location}</:item>
  <:item title="Capacity">{@meeting_room.capacity}</:item>
  <:item title="Available facility">{@meeting_room.available_facility}</:item>
  <:item title="Photo url">{@meeting_room.photo_url}</:item>
  <:item title="Status">{@meeting_room.status}</:item>
</.list>

<.back navigate={~p"/admin/meeting_rooms"}>Back to meeting_rooms</.back>

<.modal :if={@live_action == :edit} id="meeting_room-modal" show on_cancel={JS.patch(~p"/admin/meeting_rooms/#{@meeting_room}")}>
  <.live_component
    module={SpatoWeb.MeetingRoomLive.FormComponent}
    id={@meeting_room.id}
    title={@page_title}
    action={@live_action}
    meeting_room={@meeting_room}
    patch={~p"/admin/meeting_rooms/#{@meeting_room}"}
  />
</.modal>
"""
 end
end

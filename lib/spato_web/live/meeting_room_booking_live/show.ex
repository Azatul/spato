defmodule SpatoWeb.MeetingRoomBookingLive.Show do
  use SpatoWeb, :live_view

  alias Spato.Bookings

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:meeting_room_booking, Bookings.get_meeting_room_booking!(id))}
  end

  defp page_title(:show), do: "Show Meeting room booking"
  defp page_title(:edit), do: "Edit Meeting room booking"

  @impl true
  def render(assigns) do
       ~H"""
          <.header>
          Meeting room booking {@meeting_room_booking.id}
          <:subtitle>This is a meeting_room_booking record from your database.</:subtitle>
          <:actions>
            <.link patch={~p"/meeting_room_bookings/#{@meeting_room_booking}/show/edit"} phx-click={JS.push_focus()}>
              <.button>Edit meeting_room_booking</.button>
            </.link>
          </:actions>
        </.header>

        <.list>
          <:item title="Purpose">{@meeting_room_booking.purpose}</:item>
          <:item title="Participants">{@meeting_room_booking.participants}</:item>
          <:item title="Start time">{@meeting_room_booking.start_time}</:item>
          <:item title="End time">{@meeting_room_booking.end_time}</:item>
          <:item title="Status">{@meeting_room_booking.status}</:item>
          <:item title="Notes">{@meeting_room_booking.notes}</:item>
        </.list>

        <.back navigate={~p"/meeting_room_bookings"}>Back to meeting_room_bookings</.back>

        <.modal :if={@live_action == :edit} id="meeting_room_booking-modal" show on_cancel={JS.patch(~p"/meeting_room_bookings/#{@meeting_room_booking}")}>
          <.live_component
            module={SpatoWeb.MeetingRoomBookingLive.FormComponent}
            id={@meeting_room_booking.id}
            title={@page_title}
            action={@live_action}
            meeting_room_booking={@meeting_room_booking}
            patch={~p"/meeting_room_bookings/#{@meeting_room_booking}"}
          />
        </.modal>
      """
   end
end

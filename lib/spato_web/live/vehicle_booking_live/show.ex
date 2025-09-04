defmodule SpatoWeb.VehicleBookingLive.Show do
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
     |> assign(:vehicle_booking, Bookings.get_vehicle_booking!(id))}
  end

  defp page_title(:show), do: "Show Vehicle booking"
  defp page_title(:edit), do: "Edit Vehicle booking"

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Vehicle booking {@vehicle_booking.id}
      <:subtitle>This is a vehicle_booking record from your database.</:subtitle>
      <:actions>
        <.link patch={~p"/vehicle_bookings/#{@vehicle_booking}/show/edit"} phx-click={JS.push_focus()}>
          <.button>Edit vehicle_booking</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Purpose">{@vehicle_booking.purpose}</:item>
      <:item title="Trip destination">{@vehicle_booking.trip_destination}</:item>
      <:item title="Pickup time">{@vehicle_booking.pickup_time}</:item>
      <:item title="Return time">{@vehicle_booking.return_time}</:item>
      <:item title="Status">{@vehicle_booking.status}</:item>
      <:item title="Additional notes">{@vehicle_booking.additional_notes}</:item>
    </.list>

    <.back navigate={~p"/vehicle_bookings"}>Back to vehicle_bookings</.back>

    <.modal :if={@live_action == :edit} id="vehicle_booking-modal" show on_cancel={JS.patch(~p"/vehicle_bookings/#{@vehicle_booking}")}>
      <.live_component
        module={SpatoWeb.VehicleBookingLive.FormComponent}
        id={@vehicle_booking.id}
        title={@page_title}
        action={@live_action}
        vehicle_booking={@vehicle_booking}
        patch={~p"/vehicle_bookings/#{@vehicle_booking}"}
      />
    </.modal>
    """
  end
end

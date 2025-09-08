defmodule SpatoWeb.VehicleBookingLive.Index do
  use SpatoWeb, :live_view

  alias Spato.Bookings
  alias Spato.Bookings.VehicleBooking

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :vehicle_bookings, Bookings.list_vehicle_bookings())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Vehicle booking")
    |> assign(:vehicle_booking, Bookings.get_vehicle_booking!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Vehicle booking")
    |> assign(:vehicle_booking, %VehicleBooking{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Vehicle bookings")
    |> assign(:vehicle_booking, nil)
  end

  @impl true
  def handle_info({SpatoWeb.VehicleBookingLive.FormComponent, {:saved, vehicle_booking}}, socket) do
    {:noreply, stream_insert(socket, :vehicle_bookings, vehicle_booking)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    vehicle_booking = Bookings.get_vehicle_booking!(id)
    {:ok, _} = Bookings.delete_vehicle_booking(vehicle_booking)

    {:noreply, stream_delete(socket, :vehicle_bookings, vehicle_booking)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Listing Vehicle bookings
      <:actions>
        <.link patch={~p"/vehicle_bookings/new"}>
          <.button>New Vehicle booking</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="vehicle_bookings"
      rows={@streams.vehicle_bookings}
      row_click={fn {_id, vehicle_booking} -> JS.navigate(~p"/vehicle_bookings/#{vehicle_booking}") end}
    >
      <:col :let={{_id, vehicle_booking}} label="Purpose">{vehicle_booking.purpose}</:col>
      <:col :let={{_id, vehicle_booking}} label="Trip destination">{vehicle_booking.trip_destination}</:col>
      <:col :let={{_id, vehicle_booking}} label="Pickup time">{vehicle_booking.pickup_time}</:col>
      <:col :let={{_id, vehicle_booking}} label="Return time">{vehicle_booking.return_time}</:col>
      <:col :let={{_id, vehicle_booking}} label="Status">{vehicle_booking.status}</:col>
      <:col :let={{_id, vehicle_booking}} label="Additional notes">{vehicle_booking.additional_notes}</:col>
      <:action :let={{_id, vehicle_booking}}>
        <div class="sr-only">
          <.link navigate={~p"/vehicle_bookings/#{vehicle_booking}"}>Show</.link>
        </div>
        <.link patch={~p"/vehicle_bookings/#{vehicle_booking}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, vehicle_booking}}>
        <.link
          phx-click={JS.push("delete", value: %{id: vehicle_booking.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.modal :if={@live_action in [:new, :edit]} id="vehicle_booking-modal" show on_cancel={JS.patch(~p"/vehicle_bookings")}>
      <.live_component
        module={SpatoWeb.VehicleBookingLive.FormComponent}
        id={@vehicle_booking.id || :new}
        title={@page_title}
        action={@live_action}
        vehicle_booking={@vehicle_booking}
        patch={~p"/vehicle_bookings"}
      />
    </.modal>
    """
  end
end

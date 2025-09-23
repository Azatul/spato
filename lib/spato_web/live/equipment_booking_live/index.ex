defmodule SpatoWeb.EquipmentBookingLive.Index do
  use SpatoWeb, :live_view

  alias Spato.Bookings
  alias Spato.Bookings.EquipmentBooking

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :equipment_bookings, Bookings.list_equipment_bookings())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Equipment booking")
    |> assign(:equipment_booking, Bookings.get_equipment_booking!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Equipment booking")
    |> assign(:equipment_booking, %EquipmentBooking{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Equipment bookings")
    |> assign(:equipment_booking, nil)
  end

  @impl true
  def handle_info({SpatoWeb.EquipmentBookingLive.FormComponent, {:saved, equipment_booking}}, socket) do
    {:noreply, stream_insert(socket, :equipment_bookings, equipment_booking)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    equipment_booking = Bookings.get_equipment_booking!(id)
    {:ok, _} = Bookings.delete_equipment_booking(equipment_booking)

    {:noreply, stream_delete(socket, :equipment_bookings, equipment_booking)}
  end
end

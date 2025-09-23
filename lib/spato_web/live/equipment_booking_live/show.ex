defmodule SpatoWeb.EquipmentBookingLive.Show do
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
     |> assign(:equipment_booking, Bookings.get_equipment_booking!(id))}
  end

  defp page_title(:show), do: "Show Equipment booking"
  defp page_title(:edit), do: "Edit Equipment booking"
end

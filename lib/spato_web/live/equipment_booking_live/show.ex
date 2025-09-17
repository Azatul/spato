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

  @impl true
  def render(assigns) do
    ~H"""
     <.header>
        Equipment booking {@equipment_booking.id}
        <:subtitle>This is a equipment_booking record from your database.</:subtitle>
        <:actions>
          <.link patch={~p"/equipment_bookings/#{@equipment_booking}/show/edit"} phx-click={JS.push_focus()}>
            <.button>Edit equipment_booking</.button>
          </.link>
        </:actions>
      </.header>

      <.list>
        <:item title="Quantity">{@equipment_booking.quantity}</:item>
        <:item title="Location">{@equipment_booking.location}</:item>
        <:item title="Usage date">{@equipment_booking.usage_date}</:item>
        <:item title="Return date">{@equipment_booking.return_date}</:item>
        <:item title="Usage time">{@equipment_booking.usage_time}</:item>
        <:item title="Return time">{@equipment_booking.return_time}</:item>
        <:item title="Additional notes">{@equipment_booking.additional_notes}</:item>
        <:item title="Condition before">{@equipment_booking.condition_before}</:item>
        <:item title="Condition after">{@equipment_booking.condition_after}</:item>
        <:item title="Status">{@equipment_booking.status}</:item>
      </.list>

      <.back navigate={~p"/equipment_bookings"}>Back to equipment_bookings</.back>

      <.modal :if={@live_action == :edit} id="equipment_booking-modal" show on_cancel={JS.patch(~p"/equipment_bookings/#{@equipment_booking}")}>
        <.live_component
          module={SpatoWeb.EquipmentBookingLive.FormComponent}
          id={@equipment_booking.id}
          title={@page_title}
          action={@live_action}
          equipment_booking={@equipment_booking}
          patch={~p"/equipment_bookings/#{@equipment_booking}"}
        />
      </.modal>
    """
  end

end

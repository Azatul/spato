defmodule SpatoWeb.EquipmentBookingLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"booking-show-#{@id}"}>
     <.header>
        Tempahan Peralatan {@equipment_booking.id}
        <:subtitle>Lihat tempahan peralatan dalam sistem</:subtitle>
      </.header>

      <.list>
      <:item title="Peralatan">
        <%= @equipment_booking.equipment && @equipment_booking.equipment.name || "-" %>
        </:item>
        <:item title="Kuantiti">{@equipment_booking.requested_quantity} unit</:item>
        <:item title="Lokasi">{@equipment_booking.location}</:item>
        <:item title="Tarikh & Masa Guna">
          <div class="flex flex-col">
            <span class="font-medium text-gray-900">
              <%= Calendar.strftime(@equipment_booking.usage_at, "%d-%m-%Y") %>
            </span>
            <span class="text-sm text-gray-500">
              <%= Calendar.strftime(@equipment_booking.usage_at, "%H:%M") %>
            </span>
          </div>
        </:item>

        <:item title="Tarikh & Masa Pulang">
          <div class="flex flex-col">
            <span class="font-medium text-gray-900">
              <%= Calendar.strftime(@equipment_booking.return_at, "%d-%m-%Y") %>
            </span>
            <span class="text-sm text-gray-500">
              <%= Calendar.strftime(@equipment_booking.return_at, "%H:%M") %>
            </span>
          </div>
        </:item>
        <:item title="Nota tambahan">{@equipment_booking.additional_notes}</:item>
        <:item title="Status">
          <span class={"px-2 py-1 rounded-full text-white " <>
            case @equipment_booking.status do
              "pending" -> "bg-yellow-500"
              "approved" -> "bg-green-500"
              "rejected" -> "bg-red-500"
              "completed" -> "bg-blue-500"
              "cancelled" -> "bg-gray-400"
              _ -> "bg-gray-400"
            end}>
            <%= Spato.Bookings.EquipmentBooking.human_status(@equipment_booking.status) %>
          </span>
        </:item>
      </.list>

      <!-- Action Buttons -->
      <div class="flex justify-end gap-2 mt-4">
        <%= if @equipment_booking.user_id == @current_user.id and @equipment_booking.status in ["pending"] do %>
          <.link
            patch={~p"/equipment_bookings/#{@equipment_booking.id}/edit"}
            class="flex items-center justify-center w-8 h-8 rounded-full bg-blue-600 hover:bg-blue-700 text-white transition-colors"
            title="Kemaskini Tempahan">
            <.icon name="hero-pencil-square" class="w-4 h-4" />
          </.link>
        <% end %>

        <%= if @equipment_booking.status in ["pending", "approved"] do %>
          <button
            phx-click={JS.push("open_cancel_modal", value: %{id: @equipment_booking.id})}
            class="flex items-center justify-center w-8 h-8 rounded-full bg-red-600 hover:bg-red-700 text-white transition-colors"
            title="Batalkan Tempahan">
            <.icon name="hero-x-mark" class="w-4 h-4" />
          </button>
        <% end %>
      </div>
    </div>
    """
  end
end

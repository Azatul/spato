defmodule SpatoWeb.EquipmentBookingLive.AdminShowComponent do
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
        <%= @equipment_booking.equipment && @equipment_booking.equipment.name || "N/A" %>
        </:item>
        <:item title="Dibuat Oleh">
          <%= @equipment_booking.user && Spato.Accounts.User.display_name(@equipment_booking.user) || "N/A" %>
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

      <!-- Modal Footer: Action Buttons -->
      <div class="flex justify-end gap-2 mt-4">
        <%= case @equipment_booking.status do %>
          <% "pending" -> %>
            <button
              phx-click={JS.push("approve", value: %{id: @equipment_booking.id})}
              class="px-2 py-1 bg-green-600 text-white rounded hover:bg-green-700">
              Luluskan
            </button>

            <button
              phx-click={JS.push("open_reject_modal", value: %{id: @equipment_booking.id})}
              class="px-2 py-1 bg-red-600 text-white rounded hover:bg-red-700">
              Tolak
            </button>

          <% "approved" -> %>
            <button
              phx-click={JS.push("open_edit_modal", value: %{id: @equipment_booking.id})}
              class="px-2 py-1 bg-blue-600 text-white rounded hover:bg-blue-700">
              Ubah Status
            </button>

          <% "rejected" -> %>
            <%= if @equipment_booking.rejection_reason do %>
              <p class="text-sm text-gray-500">Sebab: <%= @equipment_booking.rejection_reason %></p>
            <% end %>

          <% "completed" -> %>
            <span class="text-sm text-blue-600">Selesai</span>

          <% "cancelled" -> %>
            <%= if @equipment_booking.rejection_reason do %>
              <p class="text-sm text-gray-500">Sebab: <%= @equipment_booking.rejection_reason %></p>
            <% end %>

          <% _ -> %>
            <span class="text-gray-500">—</span>
        <% end %>
      </div>
    </div>
    """
  end
end

defmodule SpatoWeb.EquipmentBookingLive.AdminShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"booking-show-#{@id}"}>
     <.header>
        Tempahan Peralatan
        <:subtitle>Maklumat penuh tempahan peralatan.</:subtitle>
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
          <span class={
            "px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
            case @equipment_booking.status do
              "pending" -> "bg-yellow-500"
              "approved" -> "bg-green-500"
              "rejected" -> "bg-red-500"
              "completed" -> "bg-blue-500"
              "cancelled" -> "bg-gray-400"
              _ -> "bg-gray-400"
            end
          }>
            <%= Spato.Bookings.EquipmentBooking.human_status(@equipment_booking.status) %>
          </span>
        </:item>
      </.list>

      <.header class="mt-6">
        Maklumat Pengguna
        <:subtitle>Butiran pengguna yang membuat tempahan.</:subtitle>
      </.header>
      <.list>
        <:item title="Nama">
          <%= if @equipment_booking.user && @equipment_booking.user.user_profile do %>
            <div class="flex flex-col">
              <span class="font-medium text-gray-900">
                <%= @equipment_booking.user.user_profile.full_name %>
              </span>
              <%= if @equipment_booking.user.user_profile.department do %>
                <span class="text-sm text-gray-500">
                  <%= @equipment_booking.user.user_profile.department.name %>
                </span>
              <% end %>
            </div>
          <% else %>
            -
          <% end %>
        </:item>
        <:item title="Emel">
          <%= @equipment_booking.user && @equipment_booking.user.email || "-" %>
        </:item>
        <:item title="No. Telefon">
          <%= if @equipment_booking.user && @equipment_booking.user.user_profile do %>
            <%= @equipment_booking.user.user_profile.phone_number || "-" %>
          <% else %>
            -
          <% end %>
        </:item>
      </.list>

      <.header class="mt-6">
        Maklumat Peralatan
        <:subtitle>Butiran peralatan yang ditempah.</:subtitle>
      </.header>
      <%= if @equipment_booking.equipment do %>
        <.list>
          <:item title="Nama"><%= @equipment_booking.equipment.name %></:item>
          <:item title="Jenis">
            <%= Spato.Assets.Equipment.human_type(@equipment_booking.equipment.type) %>
          </:item>
          <:item title="No. Siri"><%= @equipment_booking.equipment.serial_number || "-" %></:item>
          <:item title="Status">
            <%= Spato.Assets.Equipment.human_status(@equipment_booking.equipment.status) %>
          </:item>
          <:item title="Jumlah Stok"><%= @equipment_booking.equipment.total_quantity %> unit</:item>
        </.list>
      <% else %>
        <p class="mt-2 text-gray-500">Tiada maklumat peralatan dilampirkan.</p>
      <% end %>
    </div>
    """
  end
end

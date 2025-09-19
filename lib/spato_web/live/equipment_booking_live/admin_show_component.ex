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
        <%= @equipment_booking.equipment && @equipment_booking.equipment.name || "-" %>
        </:item>
        <:item title="Dibuat Oleh">
          <%= @equipment_booking.user && Spato.Accounts.User.display_name(@equipment_booking.user) || "-" %>
        </:item>
        <:item title="Kuantiti">{@equipment_booking.quantity}</:item>
        <:item title="Lokasi">{@equipment_booking.location}</:item>
        <:item title="Tarikh & Masa Guna">
          <%= @equipment_booking.usage_date %> ⏱ <%= @equipment_booking.usage_time %>
        </:item>

        <:item title="Tarikh & Masa Pulang">
          <%= @equipment_booking.return_date %> ⏱ <%= @equipment_booking.return_time %>
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
    </div>
    """
  end
end

defmodule SpatoWeb.VehicleBookingLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"vehicle-booking-show-#{@id}"}>
      <.header>
        Lihat Tempahan Kenderaan
        <:subtitle>Maklumat penuh tempahan kenderaan.</:subtitle>
      </.header>

      <!-- Booking Details -->
      <.list>
        <:item title="Tujuan">{@vehicle_booking.purpose}</:item>
        <:item title="Destinasi Perjalanan">{@vehicle_booking.trip_destination}</:item>
        <:item title="Masa Pickup">{@vehicle_booking.pickup_time}</:item>
        <:item title="Masa Pulang">{@vehicle_booking.return_time}</:item>
        <:item title="Status">{@vehicle_booking.status}</:item>
        <:item title="Catatan Tambahan">{@vehicle_booking.additional_notes}</:item>
      </.list>

      <!-- Vehicle Details -->
      <%= if @vehicle_booking.vehicle do %>
        <.list>
          <:item title="Nama Kenderaan"><%= @vehicle_booking.vehicle.name %></:item>
          <:item title="Model"><%= @vehicle_booking.vehicle.vehicle_model %></:item>
          <:item title="No. Plat"><%= @vehicle_booking.vehicle.plate_number %></:item>
          <:item title="Jenis"><%= @vehicle_booking.vehicle.type %></:item>
          <:item title="Kapasiti"><%= @vehicle_booking.vehicle.capacity %> penumpang</:item>
        </.list>
      <% else %>
        <p class="mt-6 text-gray-500">Tiada maklumat kenderaan dilampirkan.</p>
      <% end %>
    </div>
    """
  end
end

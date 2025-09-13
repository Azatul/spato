  defmodule SpatoWeb.VehicleBookingLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"vehicle-booking-show-#{@id}"}>
      <.header>
        Lihat Kenderaan
        <:subtitle>Maklumat tempahan kenderaan.</:subtitle>
      </.header>

    <.list>
      <:item title="Tujuan">{@vehicle_booking.purpose}</:item>
      <:item title="Destinasi Perjalanan">{@vehicle_booking.trip_destination}</:item>
      <:item title="Masa Pickup">{@vehicle_booking.pickup_time}</:item>
      <:item title="Masa Pulang">{@vehicle_booking.return_time}</:item>
      <:item title="Status">{@vehicle_booking.status}</:item>
      <:item title="Catatan Tambahan">{@vehicle_booking.additional_notes}</:item>
    </.list>

    </div>

    """
  end
end

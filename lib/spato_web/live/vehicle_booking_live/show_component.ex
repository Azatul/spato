defmodule SpatoWeb.VehicleBookingLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"vehicle-booking-show-#{@id}"} class="p-4 max-w-2xl mx-auto bg-white rounded-lg shadow space-y-4">
      <.header>
        Lihat Tempahan Kenderaan
        <:subtitle>Maklumat tempahan kenderaan.</:subtitle>
      </.header>

      <.list>
        <:item title="Kenderaan">
          <%= if @vehicle_booking.vehicle do %>
            <div class="flex items-center space-x-3">
              <%= if @vehicle_booking.vehicle.photo_url do %>
                <img src={@vehicle_booking.vehicle.photo_url} class="w-12 h-12 object-cover rounded-lg" />
              <% end %>
              <div>
                <div class="font-medium"><%= @vehicle_booking.vehicle.name %></div>
                <div class="text-sm text-gray-500"><%= @vehicle_booking.vehicle.plate_number %></div>
                <div class="text-xs text-gray-400"><%= @vehicle_booking.vehicle.type %> • <%= @vehicle_booking.vehicle.capacity %> penumpang</div>
              </div>
            </div>
          <% else %>
            N/A
          <% end %>
        </:item>
        <:item title="Tujuan">{@vehicle_booking.purpose}</:item>
        <:item title="Destinasi">{@vehicle_booking.trip_destination}</:item>
        <:item title="Masa Ambil">
          <%= Calendar.strftime(@vehicle_booking.pickup_time, "%d/%m/%Y %H:%M") %>
        </:item>
        <:item title="Masa Pulang">
          <%= Calendar.strftime(@vehicle_booking.return_time, "%d/%m/%Y %H:%M") %>
        </:item>
        <:item title="Status">
          <span class={
            "px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
            case @vehicle_booking.status do
              "approved" -> "bg-green-500"
              "rejected" -> "bg-red-500"
              "pending" -> "bg-yellow-500"
              "cancelled" -> "bg-gray-500"
              "completed" -> "bg-blue-500"
              _ -> "bg-gray-400"
            end
          }>
            <%= case @vehicle_booking.status do
              "approved" -> "Diluluskan"
              "rejected" -> "Ditolak"
              "pending" -> "Menunggu"
              "cancelled" -> "Dibatalkan"
              "completed" -> "Selesai"
              _ -> String.capitalize(@vehicle_booking.status)
            end %>
          </span>
        </:item>
        <:item title="Nota Tambahan">{@vehicle_booking.additional_notes}</:item>
        <:item title="Sebab Penolakan">
          <%= if @vehicle_booking.status == "rejected" do %>
            <%= @vehicle_booking.rejection_reason %>
          <% end %>
        </:item>
        <:item title="Tarikh Tempahan">
          <%= Calendar.strftime(@vehicle_booking.inserted_at, "%d/%m/%Y %H:%M") %>
        </:item>
      </.list>
    </div>
    """
  end
end

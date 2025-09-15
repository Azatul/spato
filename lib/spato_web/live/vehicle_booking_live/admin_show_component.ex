defmodule SpatoWeb.VehicleBookingLive.AdminShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"booking-show-#{@id}"}>
      <!-- Booking Header -->
      <.header>
        Lihat Tempahan Kenderaan
        <:subtitle>Butiran penuh tempahan ini.</:subtitle>
      </.header>

      <!-- Booking Details -->
      <.list>
        <:item title="Tujuan & Lokasi">
          <div class="flex flex-col">
            <span class="font-medium text-gray-900"><%= @vehicle_booking.purpose %></span>
            <span class="text-sm text-gray-500"><%= @vehicle_booking.trip_destination %></span>
          </div>
        </:item>

        <:item title="Masa Pickup">
          <div class="flex flex-col">
            <span class="font-medium text-gray-900">
              <%= Calendar.strftime(@vehicle_booking.pickup_time, "%d-%m-%Y") %>
            </span>
            <span class="text-sm text-gray-500">
              <%= Calendar.strftime(@vehicle_booking.pickup_time, "%H:%M") %>
            </span>
          </div>
        </:item>

        <:item title="Masa Pulang">
          <div class="flex flex-col">
            <span class="font-medium text-gray-900">
              <%= Calendar.strftime(@vehicle_booking.return_time, "%d-%m-%Y") %>
            </span>
            <span class="text-sm text-gray-500">
              <%= Calendar.strftime(@vehicle_booking.return_time, "%H:%M") %>
            </span>
          </div>
        </:item>

        <:item title="Status">
          <span class={
            "px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
            case @vehicle_booking.status do
              "pending" -> "bg-yellow-500"
              "approved" -> "bg-green-500"
              "rejected" -> "bg-red-500"
              "completed" -> "bg-blue-500"
              "cancelled" -> "bg-gray-400"
              _ -> "bg-gray-400"
            end
          }>
            <%= Spato.Bookings.VehicleBooking.human_status(@vehicle_booking.status) %>
          </span>
        </:item>
        <:item title="Catatan Tambahan"><%= @vehicle_booking.additional_notes || "-" %></:item>
      </.list>

      <!-- User Details -->
      <.header class="mt-6">
        Maklumat Pengguna
        <:subtitle>Butiran pengguna yang membuat tempahan.</:subtitle>
      </.header>

      <.list>
        <:item title="Nama">
          <%= if @vehicle_booking.user && @vehicle_booking.user.user_profile do %>
            <%= @vehicle_booking.user.user_profile.full_name %>
          <% else %>
            -
          <% end %>
        </:item>

        <:item title="Emel">
          <%= @vehicle_booking.user && @vehicle_booking.user.email || "-" %>
        </:item>

        <:item title="No. Telefon">
          <%= if @vehicle_booking.user && @vehicle_booking.user.user_profile do %>
            <%= @vehicle_booking.user.user_profile.phone_number || "-" %>
          <% else %>
            -
          <% end %>
        </:item>
      </.list>

      <!-- Vehicle Details -->
      <%= if @vehicle_booking.vehicle do %>
        <.header class="mt-6">
          Maklumat Kenderaan
          <:subtitle>Butiran kenderaan yang ditempah.</:subtitle>
        </.header>

        <.list>
          <:item title="Nama">
            <%= if @vehicle_booking.user && @vehicle_booking.user.user_profile do %>
              <div class="flex flex-col">
                <span class="font-medium text-gray-900">
                  <%= @vehicle_booking.user.user_profile.full_name %>
                </span>
                <%= if @vehicle_booking.user.user_profile.department do %>
                  <span class="text-sm text-gray-500">
                    <%= @vehicle_booking.user.user_profile.department.name %>
                  </span>
                <% end %>
              </div>
            <% else %>
              -
            <% end %>
          </:item>
          <:item title="Model"><%= @vehicle_booking.vehicle.vehicle_model %></:item>
          <:item title="Nombor Plat"><%= @vehicle_booking.vehicle.plate_number %></:item>
          <:item title="Jenis">
            <%= case @vehicle_booking.vehicle.type do %>
              <% "kereta" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Kereta</span>
              <% "mpv" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-indigo-500">SUV / MPV</span>
              <% "pickup" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-black text-xs font-semibold bg-yellow-400">Pickup / 4WD</span>
              <% "van" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-green-500">Van</span>
              <% "bas" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-purple-600">Bas</span>
              <% "motosikal" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-red-500">Motosikal</span>
              <% _ -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Lain</span>
            <% end %>
          </:item>
          <:item title="Kapasiti"><%= @vehicle_booking.vehicle.capacity %> penumpang</:item>
        </.list>
      <% else %>
        <p class="mt-6 text-gray-500">Tiada maklumat kenderaan dilampirkan.</p>
      <% end %>
    </div>
    """
  end
end

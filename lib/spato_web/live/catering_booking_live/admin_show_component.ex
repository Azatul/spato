defmodule SpatoWeb.CateringBookingLive.AdminShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"booking-show-#{@id}"}>
      <!-- Booking Header -->
      <.header>
        Lihat Tempahan Katering
        <:subtitle>Butiran penuh tempahan ini.</:subtitle>
      </.header>

      <!-- Booking Details -->
      <.list>
        <:item title="Lokasi & Tarikh">
          <div class="flex flex-col">
            <span class="font-medium text-gray-900"><%= @catering_booking.location %></span>
            <span class="text-sm text-gray-500"><%= Calendar.strftime(@catering_booking.date, "%d-%m-%Y") %></span>
          </div>
        </:item>

        <:item title="Masa">
          <div class="flex flex-col">
            <span class="font-medium text-gray-900">
              <%= Calendar.strftime(@catering_booking.time, "%H:%M") %>
            </span>
          </div>
        </:item>

        <:item title="Bilangan Peserta">
          <div class="flex items-center gap-1">
            <.icon name="hero-user-group" class="w-4 h-4 text-gray-500" />
            <span class="font-medium text-gray-900"><%= @catering_booking.participants %></span>
          </div>
        </:item>

        <:item title="Jumlah Kos">
          <span class="font-medium text-gray-900">RM <%= Decimal.to_string(@catering_booking.total_cost, :normal) %></span>
        </:item>

        <:item title="Status">
          <span class={
            "px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
            case @catering_booking.status do
              "pending" -> "bg-yellow-500"
              "approved" -> "bg-green-500"
              "rejected" -> "bg-red-500"
              "completed" -> "bg-blue-500"
              "cancelled" -> "bg-gray-400"
              _ -> "bg-gray-400"
            end
          }>
            <%= Spato.Bookings.CateringBooking.human_status(@catering_booking.status) %>
          </span>
        </:item>
        <:item title="Permintaan Khas"><%= @catering_booking.special_request || "-" %></:item>
      </.list>

      <!-- User Details -->
      <.header class="mt-6">
        Maklumat Pengguna
        <:subtitle>Butiran pengguna yang membuat tempahan.</:subtitle>
      </.header>

      <.list>
          <:item title="Nama">
            <%= if @catering_booking.user && @catering_booking.user.user_profile do %>
              <div class="flex flex-col">
                <span class="font-medium text-gray-900">
                  <%= @catering_booking.user.user_profile.full_name %>
                </span>
                <%= if @catering_booking.user.user_profile.department do %>
                  <span class="text-sm text-gray-500">
                    <%= @catering_booking.user.user_profile.department.name %>
                  </span>
                <% end %>
              </div>
            <% else %>
              -
            <% end %>
          </:item>

        <:item title="Emel">
          <%= @catering_booking.user && @catering_booking.user.email || "-" %>
        </:item>

        <:item title="No. Telefon">
          <%= if @catering_booking.user && @catering_booking.user.user_profile do %>
            <%= @catering_booking.user.user_profile.phone_number || "-" %>
          <% else %>
            -
          <% end %>
        </:item>
      </.list>

      <!-- Menu Details -->
      <%= if @catering_booking.menu do %>
        <.header class="mt-6">
          Maklumat Menu
          <:subtitle>Butiran menu yang ditempah.</:subtitle>
        </.header>

        <.list>
          <:item title="Nama Menu"><%= @catering_booking.menu.name %></:item>
          <:item title="Jenis">
            <%= case @catering_booking.menu.type do %>
              <% "sarapan" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-orange-500">Sarapan</span>
              <% "makan_tengah_hari" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-yellow-500">Makan Tengah Hari</span>
              <% "makan_malam" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-purple-500">Makan Malam</span>
              <% "minuman" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Minuman</span>
              <% "snek" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-green-500">Snek</span>
              <% _ -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Lain</span>
            <% end %>
          </:item>
          <:item title="Harga Seunit">RM <%= Decimal.to_string(@catering_booking.menu.price, :normal) %></:item>
          <:item title="Penerangan"><%= @catering_booking.menu.description || "-" %></:item>
        </.list>
      <% else %>
        <p class="mt-6 text-gray-500">Tiada maklumat menu dilampirkan.</p>
      <% end %>
    </div>
    """
  end
end

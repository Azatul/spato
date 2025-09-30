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
          <span class="font-medium text-gray-900">
            <%= Spato.Bookings.format_money(@catering_booking.total_cost) %>
          </span>
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
              <% "makan_tengahari" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-yellow-500">Makan Tengahari</span>
              <% "makan_malam" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-purple-500">Makan Malam</span>
              <% "minum_petang" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Minum Petang</span>
              <% "minum_malam" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-green-500">Minum Malam</span>
              <% "minum_pagi" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Minum Pagi</span>
              <% "all" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Semua</span>
              <% _ -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Semua</span>
            <% end %>
          </:item>
          <:item title="Harga Seunit"><%= Spato.Bookings.format_money(@catering_booking.menu.price_per_head) %></:item>
          <:item title="Penerangan"><%= @catering_booking.menu.description || "-" %></:item>
        </.list>
      <% else %>
        <p class="mt-6 text-gray-500">Tiada maklumat menu dilampirkan.</p>
      <% end %>

      <!-- Action Buttons -->
      <div class="flex justify-end gap-2 mt-4">
        <%= case @catering_booking.status do %>
          <% "pending" -> %>
            <button
              phx-click={JS.push("approve", value: %{id: @catering_booking.id})}
              class="px-2 py-1 bg-green-600 text-white rounded hover:bg-green-700">
              Luluskan
            </button>
            <button
              phx-click={JS.push("open_reject_modal", value: %{id: @catering_booking.id})}
              class="px-2 py-1 bg-red-600 text-white rounded hover:bg-red-700">
              Tolak
            </button>

          <% "approved" -> %>
            <button
              phx-click={JS.push("open_edit_modal", value: %{id: @catering_booking.id})}
              class="px-2 py-1 bg-blue-600 text-white rounded hover:bg-blue-700">
              Ubah Status
            </button>

          <% "rejected" -> %>
            <%= if @catering_booking.rejection_reason do %>
              <p class="text-sm text-gray-500">Sebab: <%= @catering_booking.rejection_reason %></p>
            <% end %>

          <% "completed" -> %>
            <span class="text-sm text-blue-600">Selesai</span>

          <% "cancelled" -> %>
            <%= if @catering_booking.rejection_reason do %>
              <p class="text-sm text-gray-500">Sebab: <%= @catering_booking.rejection_reason %></p>
            <% end %>

          <% _ -> %>
            <span class="text-gray-500">—</span>
        <% end %>
      </div>
    </div>
    """
  end
end

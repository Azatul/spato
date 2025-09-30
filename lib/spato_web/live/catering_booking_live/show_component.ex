defmodule SpatoWeb.CateringBookingLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"catering-booking-show-#{@id}"}>
      <.header>
        Lihat Tempahan Katering
        <:subtitle>Maklumat penuh tempahan katering.</:subtitle>
      </.header>

      <!-- Booking Details -->
      <.list>
        <:item title="Lokasi">{@catering_booking.location}</:item>
        <:item title="Bilangan Peserta">{@catering_booking.participants} orang</:item>
        <:item title="Tarikh & Masa">
          <div class="flex flex-col">
            <span class="font-medium text-gray-900">
              <%= Calendar.strftime(@catering_booking.date, "%d-%m-%Y") %>
            </span>
            <span class="text-sm text-gray-500">
              <%= Calendar.strftime(@catering_booking.time, "%H:%M") %>
            </span>
          </div>
        </:item>
        <:item title="Jumlah Kos">
            <%= Spato.Bookings.format_money(@catering_booking.total_cost) %>
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
        <:item title="Permintaan Khusus">{@catering_booking.special_request}</:item>
      </.list>

      <!-- Menu Details -->
      <%= if @catering_booking.menu do %>
        <.list>
          <:item title="Nama Menu"><%= @catering_booking.menu.name %></:item>
          <:item title="Penerangan"><%= @catering_booking.menu.description %></:item>
          <:item title="Harga Per Kepala"><%= Spato.Bookings.format_money(@catering_booking.menu.price_per_head) %></:item>
          <:item title="Jenis">
            <%= case @catering_booking.menu.type do %>
              <% "sarapan" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Sarapan</span>
              <% "makan_tengahari" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-indigo-500">Makan Tengahari</span>
              <% "minum_petang" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-black text-xs font-semibold bg-yellow-400">Minum Petang</span>
              <% "minum_malam" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-green-500">Minum Malam</span>
              <% "minum_pagi" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Minum Pagi</span>
              <% "all" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Semua</span>
              <% _ -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Lain</span>
            <% end %>
          </:item>
          <:item title="Status Menu">
            <%= case @catering_booking.menu.status do %>
              <% "tersedia" -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-green-500">Tersedia</span>
              <% _ -> %>
                <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-red-500">Tidak Tersedia</span>
            <% end %>
          </:item>
        </.list>
      <% else %>
        <p class="mt-6 text-gray-500">Tiada maklumat menu dilampirkan.</p>
      <% end %>

      <!-- Action Buttons -->
      <div class="flex justify-end gap-2 mt-4">
        <%= if @catering_booking.user_id == @current_user.id and @catering_booking.status in ["pending"] do %>
          <.link
            patch={~p"/catering_bookings/#{@catering_booking.id}/edit"}
            class="flex items-center justify-center w-8 h-8 rounded-full bg-blue-600 hover:bg-blue-700 text-white transition-colors"
            title="Kemaskini Tempahan">
            <.icon name="hero-pencil-square" class="w-4 h-4" />
          </.link>
        <% end %>

        <%= if @catering_booking.status in ["pending", "approved"] do %>
          <button
            phx-click={JS.push("open_cancel_modal", value: %{id: @catering_booking.id})}
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

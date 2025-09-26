defmodule SpatoWeb.MeetingRoomBookingLive.AdminShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"booking-show-#{@id}"}>
      <!-- Booking Header -->
      <.header>
        Lihat Tempahan Bilik Mesyuarat
        <:subtitle>Butiran penuh tempahan ini.</:subtitle>
      </.header>

      <!-- Booking Details -->
      <.list>
        <:item title="Tujuan & Lokasi">
          <div class="flex flex-col">
            <span class="font-medium text-gray-900"><%= @meeting_room_booking.purpose %></span>
            <span class="text-sm text-gray-500"><%= @meeting_room_booking.notes %></span>
          </div>
        </:item>

        <:item title="Masa Mula">
          <div class="flex flex-col">
            <span class="font-medium text-gray-900">
              <%= Calendar.strftime(@meeting_room_booking.start_time, "%d-%m-%Y") %>
            </span>
            <span class="text-sm text-gray-500">
              <%= Calendar.strftime(@meeting_room_booking.start_time, "%H:%M") %>
            </span>
          </div>
        </:item>

        <:item title="Masa Tamat">
          <div class="flex flex-col">
            <span class="font-medium text-gray-900">
              <%= Calendar.strftime(@meeting_room_booking.end_time, "%d-%m-%Y") %>
            </span>
            <span class="text-sm text-gray-500">
              <%= Calendar.strftime(@meeting_room_booking.end_time, "%H:%M") %>
            </span>
          </div>
        </:item>

        <:item title="Status">
          <span class={
            "px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
            case @meeting_room_booking.status do
              "pending" -> "bg-yellow-500"
              "approved" -> "bg-green-500"
              "rejected" -> "bg-red-500"
              "completed" -> "bg-blue-500"
              "cancelled" -> "bg-gray-400"
              _ -> "bg-gray-400"
            end
          }>
            <%= Spato.Bookings.MeetingRoomBooking.human_status(@meeting_room_booking.status) %>
          </span>
        </:item>
        <:item title="Catatan Tambahan"><%= @meeting_room_booking.notes || "-" %></:item>
      </.list>

      <!-- Action Buttons -->
      <div class="flex justify-end gap-2 mt-4">
        <%= case @meeting_room_booking.status do %>
          <% "pending" -> %>
            <button
              phx-click={JS.push("approve", value: %{id: @meeting_room_booking.id})}
              class="px-2 py-1 bg-green-600 text-white rounded hover:bg-green-700">
              Luluskan
            </button>
            <button
              phx-click={JS.push("open_reject_modal", value: %{id: @meeting_room_booking.id})}
              class="px-2 py-1 bg-red-600 text-white rounded hover:bg-red-700">
              Tolak
            </button>

          <% "approved" -> %>
            <button
              phx-click={JS.push("open_edit_modal", value: %{id: @meeting_room_booking.id})}
              class="px-2 py-1 bg-blue-600 text-white rounded hover:bg-blue-700">
              Ubah Status
            </button>

          <% "rejected" -> %>
            <%= if @meeting_room_booking.rejection_reason do %>
              <p class="text-sm text-gray-500">Sebab: <%= @meeting_room_booking.rejection_reason %></p>
            <% end %>

          <% "completed" -> %>
            <span class="text-sm text-blue-600">Selesai</span>

          <% "cancelled" -> %>
            <%= if @meeting_room_booking.rejection_reason do %>
              <p class="text-sm text-gray-500">Sebab: <%= @meeting_room_booking.rejection_reason %></p>
            <% end %>

          <% _ -> %>
            <span class="text-gray-500">—</span>
        <% end %>
      </div>

      <!-- User Details -->
      <.header class="mt-6">
        Maklumat Pengguna
        <:subtitle>Butiran pengguna yang membuat tempahan.</:subtitle>
      </.header>

      <.list>
          <:item title="Nama">
            <%= if @meeting_room_booking.user && @meeting_room_booking.user.user_profile do %>
              <div class="flex flex-col">
                <span class="font-medium text-gray-900">
                  <%= @meeting_room_booking.user.user_profile.full_name %>
                </span>
                <%= if @meeting_room_booking.user.user_profile.department do %>
                  <span class="text-sm text-gray-500">
                    <%= @meeting_room_booking.user.user_profile.department.name %>
                  </span>
                <% end %>
              </div>
            <% else %>
              -
            <% end %>
          </:item>

        <:item title="Emel">
          <%= @meeting_room_booking.user && @meeting_room_booking.user.email || "-" %>
        </:item>

        <:item title="No. Telefon">
          <%= if @meeting_room_booking.user && @meeting_room_booking.user.user_profile do %>
            <%= @meeting_room_booking.user.user_profile.phone_number || "-" %>
          <% else %>
            -
          <% end %>
        </:item>
      </.list>

      <!-- Meeting Room Details -->
      <%= if @meeting_room_booking.meeting_room do %>
        <.header class="mt-6">
          Maklumat Bilik Mesyuarat
          <:subtitle>Butiran bilik mesyuarat yang ditempah.</:subtitle>
        </.header>

        <.list>
          <:item title="Nama Bilik"><%= @meeting_room_booking.meeting_room.name%></:item>
          <:item title="Lokasi"><%= @meeting_room_booking.meeting_room.location %></:item>
          <:item title="Kapasiti">
            <%= @meeting_room_booking.participants %> / <%= @meeting_room_booking.meeting_room.capacity %> peserta
          </:item>
          <:item title="Kemudahan">
            <%= case @meeting_room_booking.meeting_room.available_facility do %>
              <% facilities when is_list(facilities) -> %>
                <div class="flex flex-wrap gap-1">
                  <%= for facility <- facilities do %>
                    <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">
                      <%= facility %>
                    </span>
                  <% end %>
                </div>
              <% _ -> %>
                <span class="text-gray-500">Tiada kemudahan tersenarai</span>
            <% end %>
          </:item>
        </.list>
      <% else %>
        <p class="mt-6 text-gray-500">Tiada maklumat bilik mesyuarat dilampirkan.</p>
      <% end %>
    </div>
    """
  end
end

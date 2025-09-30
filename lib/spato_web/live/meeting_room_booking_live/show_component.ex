defmodule SpatoWeb.MeetingRoomBookingLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"meeting-room-booking-show-#{@id}"}>
      <.header>
        Lihat Tempahan Bilik Mesyuarat
        <:subtitle>Maklumat penuh tempahan bilik mesyuarat.</:subtitle>
      </.header>

      <!-- Booking Details -->
      <.list>
        <:item title="Tujuan">{@meeting_room_booking.purpose}</:item>
        <:item title="Bilangan Peserta">{@meeting_room_booking.participants}</:item>
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
        <:item title="Catatan Tambahan">{@meeting_room_booking.notes}</:item>
      </.list>

      <!-- Meeting Room Details -->
      <%= if @meeting_room_booking.meeting_room do %>
        <.list>
          <:item title="Nama Bilik"><%= @meeting_room_booking.meeting_room.name %></:item>
          <:item title="Lokasi"><%= @meeting_room_booking.meeting_room.location %></:item>
          <:item title="Kapasiti">
            <%= @meeting_room_booking.participants %> / <%= @meeting_room_booking.meeting_room.capacity %> Orang
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

      <!-- Action Buttons -->
      <div class="flex justify-end gap-2 mt-4">
        <%= if @meeting_room_booking.user_id == @current_user.id and @meeting_room_booking.status in ["pending"] do %>
          <.link
            patch={~p"/meeting_room_bookings/#{@meeting_room_booking.id}/edit"}
            class="flex items-center justify-center w-8 h-8 rounded-full bg-blue-600 hover:bg-blue-700 text-white transition-colors"
            title="Kemaskini Tempahan">
            <.icon name="hero-pencil-square" class="w-4 h-4" />
          </.link>
        <% end %>

        <%= if @meeting_room_booking.status in ["pending", "approved"] do %>
          <button
            phx-click={JS.push("open_cancel_modal", value: %{id: @meeting_room_booking.id})}
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

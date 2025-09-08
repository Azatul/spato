defmodule SpatoWeb.MeetingRoomLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"meeting-room-show-#{@id}"}>
      <.header>
        Lihat Bilik Mesyuarat
        <:subtitle>Maklumat bilik mesyuarat.</:subtitle>
      </.header>

      <div class="mb-4">
        <%= if @meeting_room.photo_url do %>
          <img
            src={@meeting_room.photo_url}
            alt="Meeting room photo"
            class="w-full max-w-md h-48 object-cover rounded-md shadow"
          />
        <% end %>
      </div>

      <.list>
        <:item title="Nama">{@meeting_room.name}</:item>
        <:item title="Lokasi">{@meeting_room.location}</:item>
        <:item title="Kapasiti">{@meeting_room.capacity}</:item>
        <:item title="Kemudahan Tersedia">{@meeting_room.available_facility}</:item>
        <:item title="Ditambah Oleh">
          <%= @meeting_room.created_by && @meeting_room.created_by.user_profile && @meeting_room.created_by.user_profile.full_name || "N/A" %>
        </:item>
        <:item title="Tarikh & Masa Kemaskini">
          <%= Calendar.strftime(@meeting_room.updated_at, "%d/%m/%Y %H:%M") %>
        </:item>
        <:item title="Status">
          <span class={
            "px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
            case @meeting_room.status do
              "tersedia" -> "bg-green-500"
              "tidak_tersedia" -> "bg-red-500"
              _ -> "bg-gray-400"
            end
          }>
            <%= Spato.Assets.MeetingRoom.human_status(@meeting_room.status) %>
          </span>
        </:item>
      </.list>
    </div>
    """
  end
end

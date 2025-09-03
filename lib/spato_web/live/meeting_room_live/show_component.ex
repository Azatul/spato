defmodule SpatoWeb.MeetingRoomLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
      <div id={"vehicle-show-#{@id}"} class="p-4 max-w-md mx-auto bg-white rounded-lg shadow">
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
      <:item title="Name">{@meeting_room.name}</:item>
      <:item title="Location">{@meeting_room.location}</:item>
      <:item title="Capacity">{@meeting_room.capacity}</:item>
      <:item title="Available facility">{@meeting_room.available_facility}</:item>
      <:item title="Photo url">{@meeting_room.photo_url}</:item>
      <:item title="Status">{@meeting_room.status}</:item>
    </.list>
    </div>


    """
  end
end

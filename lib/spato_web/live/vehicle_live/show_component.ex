defmodule SpatoWeb.VehicleLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"vehicle-show-#{@id}"} class="p-4 max-w-md mx-auto bg-white rounded-lg shadow">
      <.header>
        Lihat Kenderaan
        <:subtitle>Maklumat kenderaan.</:subtitle>
      </.header>

      <div class="mb-4">
        <%= if @vehicle.photo_url do %>
          <img
            src={@vehicle.photo_url}
            alt="Vehicle photo"
            class="w-full max-w-md h-48 object-cover rounded-md shadow"
          />
        <% end %>
      </div>

      <.list>
        <:item title="Nama">{@vehicle.name}</:item>
        <:item title="Jenis">
          <%= case @vehicle.type do %>
            <% "kereta" -> %>
              <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Kereta</span>
            <% "mpv" -> %>
              <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-indigo-500">SUV / MPV</span>
            <% "pickup" -> %>
              <span class="px-1.5 py-0.5 rounded-full text-black text-xs font-semibold bg-yellow-400">Pickup / 4WD</span>
            <% "van" -> %>
              <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-green-500">Van</span>
            <% "bas" -> %>
              <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-purple-600">Bas / Bus</span>
            <% "motosikal" -> %>
              <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-red-500">Motosikal</span>
            <% _ -> %>
              <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Lain</span>
          <% end %>
        </:item>
        <:item title="Model">{@vehicle.vehicle_model}</:item>
        <:item title="Nombor Plat">{@vehicle.plate_number}</:item>
        <:item title="Kapasiti Penumpang">{@vehicle.capacity}</:item>
        <:item title="Status">
          <span class={
            "px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
            case @vehicle.status do
              "tersedia" -> "bg-green-500"
              "dalam_penyelenggaraan" -> "bg-red-500"
              _ -> "bg-gray-400"
            end
          }>
            <%= Spato.Assets.Vehicle.human_status(@vehicle.status) %>
          </span>
        </:item>
        <:item title="Tarikh Servis Terakhir">{@vehicle.last_services_at}</:item>
      </.list>
    </div>
    """
  end
end

defmodule SpatoWeb.VehicleLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"vehicle-show-#{@id}"} class="p-4">
      <.header>
        Lihat Kenderaan
        <:subtitle>Maklumat kenderaan.</:subtitle>
      </.header>

      <div class="mb-4">
        <%= if @vehicle.photo_url do %>
          <img src={@vehicle.photo_url} alt="Vehicle photo" class="w-full max-w-sm rounded-md shadow" />
        <% end %>
      </div>

      <.list>
        <:item title="Nama">{@vehicle.name}</:item>
        <:item title="Jenis">{@vehicle.type}</:item>
        <:item title="Model">{@vehicle.vehicle_model}</:item>
        <:item title="No. Pendaftaran">{@vehicle.plate_number}</:item>
        <:item title="Status">{@vehicle.status}</:item>
      </.list>
    </div>
    """
  end
end

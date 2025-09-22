defmodule SpatoWeb.EquipmentLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"equipment-show-#{@id}"}>
      <.header>
        Lihat Peralatan
        <:subtitle>Maklumat peralatan.</:subtitle>
      </.header>

      <div class="mb-4">
        <%= if @equipment.photo_url do %>
          <img
            src={@equipment.photo_url}
            alt="Equipment photo"
            class="w-full max-w-md h-48 object-cover rounded-md shadow"
          />
        <% end %>
      </div>

      <.list>
        <:item title="Nama">{@equipment.name}</:item>
        <:item title="Jenis">{Spato.Assets.Equipment.human_type(@equipment.type)}</:item>
        <:item title="No. Siri">{@equipment.serial_number}</:item>
        <:item title="Kuantiti Tersedia">{@equipment.total_quantity}</:item>
        <:item title="Ditambah Oleh">
          <%= @equipment.created_by && @equipment.created_by.user_profile && @equipment.created_by.user_profile.full_name || "N/A" %>
        </:item>
        <:item title="Tarikh & Masa Kemaskini">
          <%= Calendar.strftime(@equipment.updated_at, "%d/%m/%Y %H:%M") %>
        </:item>
        <:item title="Status">
          <span class={
            "px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
            case @equipment.status do
              "tersedia" -> "bg-green-500"
              "tidak_tersedia" -> "bg-red-500"
              _ -> "bg-gray-400"
            end
          }>
            <%= Spato.Assets.Equipment.human_status(@equipment.status) %>
          </span>
        </:item>
      </.list>
    </div>
    """
  end
end

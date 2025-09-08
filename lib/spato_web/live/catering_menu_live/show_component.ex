defmodule SpatoWeb.CateringMenuLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"catering-menu-show-#{@id}"}>
      <.header>
      Maklumat menu katering
      </.header>

      <div class="mb-4">
        <%= if @catering_menu.photo_url do %>
          <img
            src={@catering_menu.photo_url}
            alt="Catering menu photo"
            class="w-full max-w-md h-48 object-cover rounded-md shadow"
          />
        <% end %>
      </div>

      <.list>
        <:item title="Nama">{@catering_menu.name}</:item>
        <:item title="Keterangan">{@catering_menu.description}</:item>
        <:item title="Harga/Seorang">{@catering_menu.price_per_head}</:item>
        <:item title="Jenis">
        <span class={
          "px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
          case @catering_menu.type do
            "sarapan" -> "bg-yellow-500"
            "makan_tengahari" -> "bg-blue-500"
            "minum_petang" -> "bg-purple-500"
            _ -> "bg-gray-400"
          end
        }>
          <%= Spato.Assets.CateringMenu.human_type(@catering_menu.type) %>
        </span>
      </:item>

        <:item title="Status">
          <span class={
            "px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
            case @catering_menu.status do
              "tersedia" -> "bg-green-500"
              "tidak_tersedia" -> "bg-red-500"
              _ -> "bg-gray-400"
            end
          }>
            {@catering_menu.status}
          </span>
        </:item>
      </.list>
    </div>
    """
  end
end

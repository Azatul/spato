defmodule SpatoWeb.EquipmentLive.Show do
  use SpatoWeb, :live_view

  alias Spato.Assets

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:equipment, Assets.get_equipment!(id))}
  end

  defp page_title(:show), do: "Show Equipment"
  defp page_title(:edit), do: "Edit Equipment"

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Equipment {@equipment.id}
      <:subtitle>This is a equipment record from your database.</:subtitle>
      <:actions>
        <.link patch={~p"/admin/equipments/#{@equipment}/show/edit"} phx-click={JS.push_focus()}>
          <.button>Edit equipment</.button>
        </.link>
      </:actions>
    </.header>

    <.list>
      <:item title="Name">{@equipment.name}</:item>
      <:item title="Type">{@equipment.type}</:item>
      <:item title="Photo url">{@equipment.photo_url}</:item>
      <:item title="Serial number">{@equipment.serial_number}</:item>
      <:item title="Quantity available">{@equipment.quantity_available}</:item>
      <:item title="Status">{@equipment.status}</:item>
    </.list>

    <.back navigate={~p"/admin/equipments"}>Back to equipments</.back>

    <.modal :if={@live_action == :edit} id="equipment-modal" show on_cancel={JS.patch(~p"/admin/equipments/#{@equipment}")}>
      <.live_component
        module={SpatoWeb.EquipmentLive.FormComponent}
        id={@equipment.id}
        title={@page_title}
        action={@live_action}
        equipment={@equipment}
        patch={~p"/admin/equipments/#{@equipment}"}
      />
    </.modal>
    """
  end
end

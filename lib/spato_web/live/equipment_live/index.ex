defmodule SpatoWeb.EquipmentLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Assets
  alias Spato.Assets.Equipment

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, "manage_equipments")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> stream(:equipments, Assets.list_equipments())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Equipment")
    |> assign(:equipment, Assets.get_equipment!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Equipment")
    |> assign(:equipment, %Equipment{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Equipments")
    |> assign(:equipment, nil)
  end

  @impl true
  def handle_info({SpatoWeb.EquipmentLive.FormComponent, {:saved, equipment}}, socket) do
    {:noreply, stream_insert(socket, :equipments, equipment)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    equipment = Assets.get_equipment!(id)
    {:ok, _} = Assets.delete_equipment(equipment)

    {:noreply, stream_delete(socket, :equipments, equipment)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
      <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

      <main class="flex-1 pt-20 p-6 transition-all duration-300 overflow-y-auto bg-gray-100">
        <.header>
          Listing Equipments
          <:actions>
            <.link patch={~p"/admin/equipments/new"}>
              <.button>New Equipment</.button>
            </.link>
          </:actions>
        </.header>

        <.table
          id="equipments"
          rows={@streams.equipments}
          row_click={fn {_id, equipment} -> JS.navigate(~p"/admin/equipments/#{equipment}") end}
        >
          <:col :let={{_id, equipment}} label="Name">{equipment.name}</:col>
          <:col :let={{_id, equipment}} label="Type">{equipment.type}</:col>
          <:col :let={{_id, equipment}} label="Photo url">{equipment.photo_url}</:col>
          <:col :let={{_id, equipment}} label="Serial number">{equipment.serial_number}</:col>
          <:col :let={{_id, equipment}} label="Quantity available">{equipment.quantity_available}</:col>
          <:col :let={{_id, equipment}} label="Status">{equipment.status}</:col>
          <:action :let={{_id, equipment}}>
            <div class="sr-only">
              <.link navigate={~p"/admin/equipments/#{equipment}"}>Show</.link>
            </div>
            <.link patch={~p"/admin/equipments/#{equipment}/edit"}>Edit</.link>
          </:action>
          <:action :let={{id, equipment}}>
            <.link
              phx-click={JS.push("delete", value: %{id: equipment.id}) |> hide("##{id}")}
              data-confirm="Are you sure?"
            >
              Delete
            </.link>
          </:action>
        </.table>

        <.modal :if={@live_action in [:new, :edit]} id="equipment-modal" show on_cancel={JS.patch(~p"/admin/equipments")}>
          <.live_component
            module={SpatoWeb.EquipmentLive.FormComponent}
            id={@equipment.id || :new}
            title={@page_title}
            action={@live_action}
            equipment={@equipment}
            patch={~p"/admin/equipments"}
          />
        </.modal>
      </main>
    </div>
    """
  end
end

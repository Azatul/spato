defmodule SpatoWeb.VehicleLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Assets
  alias Spato.Assets.Vehicle

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    vehicles = Assets.list_vehicles()

    {:ok,
     socket
     |> assign(:page_title, "Senarai Kenderaan")
     |> assign(:active_tab, "manage_vehicles")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> stream(:vehicles, vehicles)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Kemaskini Kenderaan")
    |> assign(:vehicle, Assets.get_vehicle!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Tambah Kenderaan")
    |> assign(:vehicle, %Vehicle{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Senarai Kenderaan")
    |> assign(:vehicle, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Lihat Kenderaan")
    |> assign(:vehicle, Assets.get_vehicle!(id))
  end

  @impl true
  def handle_info({SpatoWeb.VehicleLive.FormComponent, {:saved, vehicle}}, socket) do
    {:noreply, stream_insert(socket, :vehicles, vehicle)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    vehicle = Assets.get_vehicle!(id)
    {:ok, _} = Assets.delete_vehicle(vehicle)

    {:noreply, stream_delete(socket, :vehicles, vehicle)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
      <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

      <main class="flex-1 pt-16 p-6 transition-all duration-300">
        <div class="bg-gray-100 p-4 md:p-8 rounded-lg">
          <h1 class="text-xl font-bold mb-1">Senarai Kenderaan</h1>
          <p class="text-md text-gray-500 mb-6">Semak semua kenderaan dalam sistem</p>

          <header class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold text-gray-900">Senarai Kenderaan</h2>
            <.link patch={~p"/admin/vehicles/new"}>
              <.button class="inline-flex items-center justify-center rounded-md border border-transparent bg-gray-900 px-4 py-2 text-sm font-semibold text-white hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-800 focus:ring-offset-2">Tambah Kenderaan</.button>
            </.link>
          </header>

          <.table
            id="vehicles"
            rows={@streams.vehicles}
            row_click={fn {_id, vehicle} -> JS.patch(~p"/admin/vehicles/#{vehicle}?action=show") end}
          >
            <:col :let={{_id, vehicle}} label="Nama Kenderaan">{vehicle.name}</:col>
            <:col :let={{_id, vehicle}} label="Nombor Plat">{vehicle.plate_number}</:col>
            <:col :let={{_id, vehicle}} label="Jenis">{vehicle.type}</:col>
            <:col :let={{_id, vehicle}} label="Model">{vehicle.vehicle_model}</:col>
            <:col :let={{_id, vehicle}} label="Kapasiti">{vehicle.capacity}</:col>
            <:col :let={{_id, vehicle}} label="Status">{vehicle.status}</:col>
            <:action :let={{_id, vehicle}}>
              <.link patch={~p"/admin/vehicles/#{vehicle}/edit"}>Kemaskini</.link>
            </:action>
            <:action :let={{id, vehicle}}>
              <.link
                phx-click={JS.push("delete", value: %{id: vehicle.id}) |> hide("##{id}")}
                data-confirm="Are you sure you want to delete this vehicle?"
              >
                Padam
              </.link>
            </:action>
          </.table>

          <.modal :if={@live_action in [:new, :edit]} id="vehicle-modal" show on_cancel={JS.patch(~p"/admin/vehicles")}>
            <.live_component
              module={SpatoWeb.VehicleLive.FormComponent}
              id={@vehicle.id || :new}
              title={@page_title}
              action={@live_action}
              vehicle={@vehicle}
              patch={~p"/admin/vehicles"}
            />
          </.modal>

          <!-- Show Modal -->
          <.modal :if={@live_action == :show} id="vehicle-show-modal" show on_cancel={JS.patch(~p"/admin/vehicles")}>
            <.live_component
              module={SpatoWeb.VehicleLive.ShowComponent}
              id={@vehicle.id}
              vehicle={@vehicle}
            />
          </.modal>

        </div>
      </main>
    </div>
    """
  end
end

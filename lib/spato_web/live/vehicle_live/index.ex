defmodule SpatoWeb.VehicleLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Assets
  alias Spato.Assets.Vehicle

  @per_page 10
  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    vehicles = Assets.list_vehicles()
    stats = %{
      total: length(vehicles),
      available: Enum.count(vehicles, &(&1.status == "tersedia")),
      maintenance: Enum.count(vehicles, &(&1.status == "dalam_penyelenggaraan")),
      active: Enum.count(vehicles, &(&1.status == "tersedia"))
    }

    socket =
      socket
      |> assign(:page_title, "Senarai Kenderaan")
      |> assign(:active_tab, "manage_vehicles")
      |> assign(:sidebar_open, true)
      |> assign(:current_user, socket.assigns.current_user)
      |> assign(:stats, stats)
      |> assign(:filter_status, "all")
      |> assign(:search_query, "")
      |> assign(:vehicles, vehicles)
      |> assign(:page, 1)
      |> assign(:vehicle, nil)

    {:ok, assign_pagination(socket)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()

    socket =
      socket
      |> assign(:page, page)
      |> update_filtered_vehicles()
      |> assign_pagination()
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  # Filter & search events
  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    socket =
      socket
      |> assign(:filter_status, status)
      |> assign(:page, 1)
      |> update_filtered_vehicles()
      |> assign_pagination()

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    socket =
      socket
      |> assign(:search_query, query)
      |> assign(:page, 1)
      |> update_filtered_vehicles()
      |> assign_pagination()

    {:noreply, socket}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    page = String.to_integer(page)

    socket =
      socket
      |> assign(:page, page)
      |> assign(:vehicles_page, paginated_vehicles(socket.assigns.vehicles, page))

    {:noreply, push_patch(socket, to: ~p"/admin/vehicles?page=#{page}")}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    vehicle = Assets.get_vehicle!(id)
    {:ok, _} = Assets.delete_vehicle(vehicle)

    vehicles = Enum.reject(socket.assigns.vehicles, fn v -> v.id == vehicle.id end)

    socket =
      socket
      |> assign(:vehicles, vehicles)
      |> assign_pagination()

    {:noreply, socket}
  end

  # Form saved
  @impl true
  def handle_info({SpatoWeb.VehicleLive.FormComponent, {:saved, vehicle}}, socket) do
    vehicles = [vehicle | socket.assigns.vehicles]

    socket =
      socket
      |> assign(:vehicles, vehicles)
      |> assign_pagination()

    {:noreply, socket}
  end

  # --- Helpers ---
  defp apply_action(socket, :edit, %{"id" => id}) do
    assign(socket,
      page_title: "Kemaskini Kenderaan",
      vehicle: Assets.get_vehicle!(id)
    )
  end

  defp apply_action(socket, :new, _params) do
    assign(socket,
      page_title: "Tambah Kenderaan",
      vehicle: %Vehicle{}
    )
  end

  defp apply_action(socket, :index, _params) do
    assign(socket,
      page_title: "Senarai Kenderaan",
      vehicle: nil
    )
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    assign(socket,
      page_title: "Lihat Kenderaan",
      vehicle: Assets.get_vehicle!(id)
    )
  end

  # Combine filter and search
  defp update_filtered_vehicles(socket) do
    filtered =
      Assets.list_vehicles()
      |> Enum.filter(fn v ->
        (socket.assigns.filter_status == "all" or v.status == socket.assigns.filter_status) and
          (socket.assigns.search_query == "" or
             String.contains?(String.downcase(v.name), String.downcase(socket.assigns.search_query)) or
             String.contains?(String.downcase(v.type), String.downcase(socket.assigns.search_query)) or
             String.contains?(Integer.to_string(v.capacity), socket.assigns.search_query) or
             String.contains?(String.downcase(v.plate_number), String.downcase(socket.assigns.search_query)))
      end)

    assign(socket, :vehicles, filtered)
  end

  # Pagination helpers
  defp paginated_vehicles(vehicles, page) do
    vehicles
    |> Enum.chunk_every(@per_page)
    |> Enum.at(page - 1, [])
  end

  defp total_pages(vehicles) do
    (Enum.count(vehicles) / @per_page) |> Float.ceil() |> trunc()
  end

  defp assign_pagination(socket) do
    vehicles_page = paginated_vehicles(socket.assigns.vehicles, socket.assigns.page)
    total_pages = total_pages(socket.assigns.vehicles)
    assign(socket, vehicles_page: vehicles_page, total_pages: total_pages)
  end

  # --- Render ---
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

          <!-- Stats Cards -->
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <%= for {label, value} <- [{"Jumlah Kenderaan Berdaftar", @stats.total}, {"Kenderaan Tersedia", @stats.available}, {"Dalam Penyelenggaraan", @stats.maintenance}, {"Kenderaan Aktif", @stats.active}] do %>
              <div class="bg-white p-4 rounded-xl shadow-md flex flex-col justify-between h-30 transition-transform hover:scale-105">
                <div>
                  <p class="text-sm text-gray-500"><%= label %></p>
                  <p class="text-3xl font-bold mt-1"><%= value %></p>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Header: Search + Add + Filter -->
          <div class="flex items-center justify-between mb-4 space-x-2">
            <h2 class="text-lg font-semibold text-gray-900">Senarai Kenderaan</h2>

            <form phx-change="search">
              <input type="text" name="q" value={@search_query} placeholder="Cari nama, jenis atau kapasiti..." class="border rounded-md px-2 py-1 text-sm"/>
            </form>

            <.link patch={~p"/admin/vehicles/new"}>
              <.button class="bg-gray-900 text-white px-4 py-2 rounded-md hover:bg-gray-700">Tambah Kenderaan</.button>
            </.link>

            <form phx-change="filter_status" class="inline-block">
              <select name="status" class="border rounded-md px-2 py-1 text-sm">
                <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                <option value="tersedia" selected={@filter_status == "tersedia"}>Tersedia</option>
                <option value="dalam_penyelenggaraan" selected={@filter_status == "dalam_penyelenggaraan"}>Dalam Penyelenggaraan</option>
              </select>
            </form>
          </div>

          <!-- Vehicles Table -->
          <.table id="vehicles" rows={@vehicles_page} row_click={fn vehicle -> JS.patch(~p"/admin/vehicles/#{vehicle.id}?action=show") end}>
            <:col :let={vehicle} label="Nama Kenderaan">{vehicle.name}</:col>
            <:col :let={vehicle} label="Nombor Plat">{vehicle.plate_number}</:col>
            <:col :let={vehicle} label="Jenis">{vehicle.type}</:col>
            <:col :let={vehicle} label="Kapasiti Penumpang">{vehicle.capacity}</:col>
            <:col :let={vehicle} label="Tarikh & Masa Dikemaskini">
              <%= "#{String.pad_leading(Integer.to_string(vehicle.updated_at.day), 2, "0")}/" <>
                  "#{String.pad_leading(Integer.to_string(vehicle.updated_at.month), 2, "0")}/" <>
                  "#{vehicle.updated_at.year} " <>
                  "#{String.pad_leading(Integer.to_string(vehicle.updated_at.hour), 2, "0")}:" <>
                  "#{String.pad_leading(Integer.to_string(vehicle.updated_at.minute), 2, "0")}:" <>
                  "#{String.pad_leading(Integer.to_string(vehicle.updated_at.second), 2, "0")}" %>
            </:col>

            <:col :let={vehicle} label="Status">
              <span class={"px-2 py-1 rounded-full text-white text-xs font-semibold " <>
                case vehicle.status do
                  "tersedia" -> "bg-green-500"
                  "dalam_penyelenggaraan" -> "bg-yellow-500"
                  _ -> "bg-gray-400"
                end
              }>
                <%= Spato.Assets.Vehicle.human_status(vehicle.status) %>
              </span>
            </:col>
            <:action :let={vehicle}>
              <.link patch={~p"/admin/vehicles/#{vehicle.id}/edit"}>Kemaskini</.link>
            </:action>
            <:action :let={vehicle}>
              <.link phx-click={JS.push("delete", value: %{id: vehicle.id}) |> hide("##{vehicle.id}")} data-confirm="Padam vehicle?">Padam</.link>
            </:action>
          </.table>

          <!-- Pagination -->
          <div class="flex space-x-1 mt-4">
            <%= for p <- 1..@total_pages do %>
              <.link patch={~p"/admin/vehicles?page=#{p}"} class={"px-3 py-1 border rounded #{if p == @page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700"}"}>
                <%= p %>
              </.link>
            <% end %>
          </div>

          <!-- Modals -->
          <.modal :if={@live_action in [:new, :edit]} id="vehicle-modal" show on_cancel={JS.patch(~p"/admin/vehicles")}>
            <.live_component module={SpatoWeb.VehicleLive.FormComponent} id={@vehicle.id || :new} title={@page_title} action={@live_action} vehicle={@vehicle} patch={~p"/admin/vehicles"} />
          </.modal>

          <.modal :if={@live_action == :show} id="vehicle-show-modal" show on_cancel={JS.patch(~p"/admin/vehicles")}>
            <.live_component module={SpatoWeb.VehicleLive.ShowComponent} id={@vehicle.id} vehicle={@vehicle} />
          </.modal>
        </div>
      </main>
    </div>
    """
  end
end

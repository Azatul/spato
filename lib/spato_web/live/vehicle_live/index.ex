defmodule SpatoWeb.VehicleLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Assets
  alias Spato.Assets.Vehicle

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: :timer.send_interval(5_000, self(), :reload_vehicles)
    {:ok,
     socket
     |> assign(:page_title, "Senarai Kenderaan")
     |> assign(:active_tab, "manage_vehicles")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:filter_status, "all")
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> load_vehicles()}
  end

  # --- LOAD VEHICLES ---
  defp load_vehicles(socket) do
    params = %{
      "page" => socket.assigns.page,
      "search" => socket.assigns.search_query,
      "status" => socket.assigns.filter_status
    }

    data = Assets.list_vehicles_paginated(params)

     # Global stats (not affected by filters)
      all_vehicles = Assets.list_vehicles()
      stats = %{
        total: length(all_vehicles),
        available: Enum.count(all_vehicles, &(&1.status == "tersedia")),
        maintenance: Enum.count(all_vehicles, &(&1.status == "dalam_penyelenggaraan")),
        active: Enum.count(all_vehicles, &(&1.status == "tersedia"))
      }

    socket
    |> assign(:vehicles_page, data.vehicles_page)
    |> assign(:total_pages, data.total_pages)
    |> assign(:stats, stats)
    |> assign(:filtered_count, data.total)
  end

  # --- HANDLE EVENTS ---
  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 1)
     |> load_vehicles()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, status)
     |> assign(:page, 1)
     |> load_vehicles()}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, String.to_integer(page))
     |> load_vehicles()}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket), do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    vehicle = Assets.get_vehicle!(id)
    {:ok, _} = Assets.delete_vehicle(vehicle)
    {:noreply, load_vehicles(socket)}
  end

  @impl true
  def handle_info({SpatoWeb.VehicleLive.FormComponent, {:saved, _vehicle}}, socket) do
    {:noreply, load_vehicles(socket)}
  end

  @impl true
  def handle_info(:reload_vehicles, socket) do
    {:noreply, load_vehicles(socket)}
  end

  # --- ACTIONS FOR MODALS ---
  defp apply_action(socket, :new, _params), do: assign(socket, page_title: "Tambah Kenderaan", vehicle: %Vehicle{})
  defp apply_action(socket, :edit, %{"id" => id}), do: assign(socket, page_title: "Kemaskini Kenderaan", vehicle: Assets.get_vehicle!(id))
  defp apply_action(socket, :show, %{"id" => id}), do: assign(socket, page_title: "Lihat Kenderaan", vehicle: Assets.get_vehicle!(id))
  defp apply_action(socket, :index, _params), do: assign(socket, page_title: "Senarai Kenderaan", vehicle: nil)

  @impl true
  def handle_params(params, _url, socket) do
    page   = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "q", "")
    status = Map.get(params, "status", "all")

    {:noreply,
    socket
    |> assign(:page, page)
    |> assign(:search_query, search)
    |> assign(:filter_status, status)
    |> load_vehicles()
    |> apply_action(socket.assigns.live_action, params)}
  end

  # --- RENDER ---
  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
      <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

      <main class="flex-1 pt-16 p-6 transition-all duration-300 overflow-y-auto">
        <div class="bg-gray-100 p-4 md:p-8 rounded-lg">
          <h1 class="text-xl font-bold mb-1">Senarai Kenderaan</h1>
          <p class="text-md text-gray-500 mb-6">Semak semua kenderaan dalam sistem</p>

          <!-- Stats Cards -->
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <%= for {label, value} <- [{"Jumlah Kenderaan Berdaftar", @stats.total},
                                      {"Kenderaan Tersedia", @stats.available},
                                      {"Dalam Penyelenggaraan", @stats.maintenance},
                                      {"Kenderaan Aktif", @stats.active}] do %>

              <% number_color =
                case label do
                  "Jumlah Kenderaan Berdaftar" -> "text-gray-700"
                  "Kenderaan Tersedia" -> "text-green-500"
                  "Dalam Penyelenggaraan" -> "text-red-500"
                  "Kenderaan Aktif" -> "text-blue-500"
                end %>

              <div class="bg-white p-4 rounded-xl shadow-md flex flex-col justify-between h-30 transition-transform hover:scale-105">
                <div>
                  <p class="text-sm text-gray-500"><%= label %></p>
                  <p class={"text-3xl font-bold mt-1 #{number_color}"}><%= value %></p>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Header: Add + Search + Filter -->
          <div class="flex flex-col mb-4 gap-2">
            <div class="flex items-center justify-between">
              <h2 class="text-lg font-semibold text-gray-900">Senarai Kenderaan</h2>
              <.link patch={~p"/admin/vehicles/new"}>
                <.button class="bg-gray-900 text-white px-4 py-2 rounded-md hover:bg-gray-700">Tambah Kenderaan</.button>
              </.link>
            </div>

            <div class="flex flex-wrap gap-2 mt-2">
              <form phx-change="search" class="flex-1 min-w-[200px]">
                <input type="text" name="q" value={@search_query} placeholder="Cari nama, jenis atau kapasiti..." class="w-full border rounded-md px-2 py-1 text-sm"/>
              </form>

              <form phx-change="filter_status">
                <select name="status" class="border rounded-md px-2 py-1 text-sm">
                  <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                  <option value="tersedia" selected={@filter_status == "tersedia"}>Tersedia</option>
                  <option value="dalam_penyelenggaraan" selected={@filter_status == "dalam_penyelenggaraan"}>Dalam Penyelenggaraan</option>
                </select>
              </form>
            </div>
          </div>

          <!-- Vehicles count message -->
          <div class="mb-2 text-sm text-gray-600">
            <%= if @filtered_count == 0 do %>
              Tiada kenderaan ditemui
            <% else %>
              <%= @filtered_count %> kenderaan ditemui
            <% end %>
          </div>

          <!-- Vehicles Table -->
          <.table id="vehicles" rows={@vehicles_page} row_click={fn vehicle ->
            JS.patch(
              ~p"/admin/vehicles/#{vehicle.id}?action=show&page=#{@page}&q=#{@search_query}&status=#{@filter_status}"
            )
          end}>
            <:col :let={vehicle} label="ID"><%= vehicle.id %></:col>
            <:col :let={vehicle} label="Kenderaan">
              <div class="flex flex-col">
                <!-- Vehicle Name -->
                <div class="font-semibold text-gray-900">
                  <%= vehicle.name %>
                </div>

                <!-- Plate Number -->
                <div class="text-sm text-gray-500">
                  <%= vehicle.plate_number %>
                </div>

                <!-- Vehicle Type (colored pill badge) -->
                <div class="mt-1">
                  <%= case vehicle.type do %>
                    <% "kereta" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Kereta</span>
                    <% "mpv" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-indigo-500">SUV / MPV</span>
                    <% "pickup" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-black text-xs font-semibold bg-yellow-400">Pickup / 4WD</span>
                    <% "van" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-green-500">Van</span>
                    <% "bas" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-purple-600">Bas</span>
                    <% "motosikal" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-red-500">Motosikal</span>
                    <% _ -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Lain</span>
                  <% end %>
                </div>
              </div>
            </:col>
            <:col :let={vehicle} label="Kapasiti">{vehicle.capacity}</:col>
            <:col :let={vehicle} label="Tarikh Servis Terakhir">
              <%= Calendar.strftime(vehicle.last_services_at, "%d/%m/%Y") %>
            </:col>
            <:col :let={vehicle} label="Ditambah Oleh">
              <%= vehicle.user && vehicle.user.user_profile && vehicle.user.user_profile.full_name || "N/A" %>
            </:col>
            <:col :let={vehicle} label="Tarikh & Masa Kemaskini">
              <%= Calendar.strftime(vehicle.updated_at, "%d/%m/%Y %H:%M") %>
            </:col>
            <:col :let={vehicle} label="Status">
              <span class={"px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
                case vehicle.status do
                  "tersedia" -> "bg-green-500"
                  "dalam_penyelenggaraan" -> "bg-red-500"
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
          <div class="relative flex items-center mt-4">
            <!-- Previous button -->
            <div class="flex-1">
              <.link
                patch={~p"/admin/vehicles?page=#{max(@page - 1, 1)}&q=#{@search_query}&status=#{@filter_status}"}
                class={"px-3 py-1 border rounded #{if @page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
              >
                Sebelumnya
              </.link>
            </div>

            <!-- Page numbers (centered) -->
            <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
              <%= for p <- 1..@total_pages do %>
                <.link
                  patch={~p"/admin/vehicles?page=#{p}&q=#{@search_query}&status=#{@filter_status}"}
                  class={"px-3 py-1 border rounded #{if p == @page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
                >
                  <%= p %>
                </.link>
              <% end %>
            </div>

            <!-- Next button -->
            <div class="flex-1 text-right">
              <.link
                patch={~p"/admin/vehicles?page=#{min(@page + 1, @total_pages)}&q=#{@search_query}&status=#{@filter_status}"}
                class={"px-3 py-1 border rounded #{if @page == @total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
              >
                Seterusnya
              </.link>
            </div>
          </div>

          <!-- Modals -->
          <.modal :if={@live_action in [:new, :edit]} id="vehicle-modal" show on_cancel={JS.patch(~p"/admin/vehicles")}>
            <.live_component
              module={SpatoWeb.VehicleLive.FormComponent}
              id={@vehicle.id || :new}
              title={@page_title}
              action={@live_action}
              vehicle={@vehicle}
              patch={~p"/admin/vehicles"}
              current_user={@current_user}
              current_user_id={@current_user.id}
            />
          </.modal>

          <.modal :if={@live_action == :show} id="vehicle-show-modal" show on_cancel={JS.patch(~p"/admin/vehicles?page=#{@page}&q=#{@search_query}&status=#{@filter_status}")}>
            <.live_component module={SpatoWeb.VehicleLive.ShowComponent} id={@vehicle.id} vehicle={@vehicle} />
          </.modal>
        </div>
      </main>
    </div>
    """
  end
end

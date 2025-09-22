defmodule SpatoWeb.AvailableVehicleLive do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Bookings
  alias Spato.Bookings.VehicleBooking

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    filters = %{
      "query" => "",
      "type" => "all",
      "capacity" => "",
      "pickup_time" => nil,
      "return_time" => nil
    }

    {:ok,
     socket
     |> assign(:page_title, "Kenderaan Tersedia")
     |> assign(:active_tab, "vehicles")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:vehicles, [])
     |> assign(:filters, filters)
     |> assign(:form, to_form(filters))
     |> assign(:page, 1)
     |> assign(:total_pages, 1)
     |> assign(:total, 0)
     |> assign(:vehicle_booking, nil)
     |> assign(:params, %{})
     |> assign(:live_action, :index)}
  end

  defp load_vehicles(socket) do
    filters =
      socket.assigns.filters
      |> Map.put("page", socket.assigns.page)

    %{vehicles_page: vehicles, total: total, total_pages: total_pages, page: page} =
      Bookings.available_vehicles(filters)

    socket
    |> assign(:vehicles, vehicles)
    |> assign(:page, page)
    |> assign(:total_pages, total_pages)
    |> assign(:total, total)
  end

  @impl true
  def handle_event("search", params, socket) do
    filters =
      case params do
        %{"filters" => filters} -> filters
        filters when is_map(filters) -> filters
      end

      new_filters = %{
        "query" => Map.get(filters, "query", ""),
        "type" => Map.get(filters, "type", "all"),
        "capacity" => Map.get(filters, "capacity", ""),
        "pickup_time" => Map.get(filters, "pickup_time", ""),
        "return_time" => Map.get(filters, "return_time", "")
      }

    {:noreply,
     socket
     |> assign(:filters, new_filters)
     |> assign(:form, to_form(filters)) # keep form fields as raw strings
     |> assign(:page, 1)
     |> load_vehicles()}
  end

  @impl true
  def handle_event("next_page", _, socket) do
    if socket.assigns.page < socket.assigns.total_pages do
      {:noreply, socket |> assign(:page, socket.assigns.page + 1) |> load_vehicles()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("prev_page", _, socket) do
    if socket.assigns.page > 1 do
      {:noreply, socket |> assign(:page, socket.assigns.page - 1) |> load_vehicles()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket),
    do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      case params["action"] do
        "new" ->
          vehicle_booking = %VehicleBooking{}

          socket
          |> assign(:live_action, :new)
          |> assign(:page_title, "Tambah Tempahan Kenderaan")
          |> assign(:vehicle_booking, vehicle_booking)
          |> assign(:params, params)

        _ ->
          socket
          |> assign(:live_action, :index)
          |> assign(:vehicle_booking, nil)
      end

    {:noreply, socket |> load_vehicles()}
  end

  @impl true
  def handle_info({SpatoWeb.VehicleBookingLive.FormComponent, {:saved, _booking}}, socket) do
    {:noreply, socket |> load_vehicles()}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
      <div class="flex flex-col flex-1">
        <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

        <main class="flex-1 overflow-y-auto pt-20 p-6 transition-all duration-300 bg-gray-100">
          <section class="mb-4">
            <h1 class="text-xl font-bold mb-1">Kenderaan Tersedia</h1>
            <p class="text-md text-gray-500 mb-4">Cari dan tempah kenderaan yang tersedia</p>

            <!-- Middle Section: Add Vehicle Button -->
            <section class="mb-4 flex justify-end">
              <.link patch={~p"/vehicle_bookings"}>
                    <.button class="bg-gray-900 text-white px-4 py-2 rounded-md hover:bg-gray-700">Lihat Senarai Tempahan</.button>
                  </.link>
            </section>

          <!-- Filters -->
          <.form for={@form} phx-submit="search" class="mb-6 bg-white p-4 rounded-xl shadow-md w-full">
            <div class="flex flex-wrap items-end gap-4 w-full">

              <!-- Search box flexes -->
              <div class="flex-1 min-w-[150px]">
                <.input
                  field={@form[:query]}
                  label="Carian"
                  placeholder="Cari kenderaan, nombor plat..."
                  class="w-full"
                />
              </div>

              <!-- Right inputs + button: fixed group -->
              <div class="flex flex-wrap items-end gap-4 min-w-0">
                <.input
                  field={@form[:capacity]}
                  type="number"
                  label="Kapasiti"
                  placeholder="0"
                  class="w-32"
                />

                <.input
                  field={@form[:type]}
                  type="select"
                  label="Jenis"
                  options={[
                    {"Semua", "all"},
                    {"SUV / MPV", "mpv"},
                    {"Van", "van"},
                    {"Kereta", "kereta"},
                    {"Pickup / 4WD", "pickup"},
                    {"Bas", "bas"},
                    {"Motosikal", "motosikal"}
                  ]}
                  class="w-32"
                />

                <.input
                  field={@form[:pickup_time]}
                  type="datetime-local"
                  label="Tarikh & Masa Ambil"
                  class="w-44"
                />

                <.input
                  field={@form[:return_time]}
                  type="datetime-local"
                  label="Tarikh & Masa Pulang"
                  class="w-44"
                />

                <.button
                  type="submit"
                  class="bg-gray-900 text-white px-5 py-2 rounded-lg shadow-md hover:bg-gray-700 transition flex-shrink-0"
                >
                  Cari
                </.button>
              </div>

            </div>
          </.form>

            <!-- Vehicles grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              <%= for vehicle <- @vehicles do %>
                <div class="bg-white rounded-2xl shadow-md p-4 hover:shadow-lg transition-shadow">
                  <div class="relative mb-3">
                    <img src={vehicle.photo_url || "/images/vehicle.jpg"} class="w-full h-40 object-cover rounded-lg" />
                    <div class="absolute top-2 right-2">
                      <%= case vehicle.type do %>
                        <% "kereta" -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Kereta</span>
                        <% "mpv" -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-indigo-500">SUV / MPV</span>
                        <% "pickup" -> %><span class="px-1.5 py-0.5 rounded-full text-black text-xs font-semibold bg-yellow-400">Pickup / 4WD</span>
                        <% "van" -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-green-500">Van</span>
                        <% "bas" -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-purple-600">Bas</span>
                        <% "motosikal" -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-red-500">Motosikal</span>
                        <% _ -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Lain</span>
                      <% end %>
                    </div>
                  </div>

                  <h3 class="font-bold text-lg mb-1"><%= vehicle.name %></h3>
                  <p class="text-gray-600 mb-2"><%= vehicle.plate_number %></p>
                  <p class="text-sm text-gray-500 mb-3"><%= vehicle.capacity %> penumpang</p>

                  <%= if @filters["pickup_time"] not in [nil, ""] and @filters["return_time"] not in [nil, ""] do %>
                    <.link
                      patch={~p"/available_vehicles?#{%{
                        action: "new",
                        vehicle_id: vehicle.id,
                        pickup_time: @filters["pickup_time"],
                        return_time: @filters["return_time"]
                      }}"}
                      class="block"
                    >
                      <.button class="w-full bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
                        Tempah Sekarang
                      </.button>
                    </.link>
                  <% else %>
                    <button class="w-full bg-gray-300 text-gray-500 px-4 py-2 rounded-md cursor-not-allowed" disabled>
                      Pilih Tarikh & Masa Dahulu
                    </button>
                  <% end %>
                </div>
              <% end %>
            </div>

            <%= if Enum.empty?(@vehicles) do %>
              <div class="text-center py-12">
                <%= if @filters["pickup_time"] not in [nil, ""] and @filters["return_time"] not in [nil, ""] do %>
                  <p class="text-red-500 text-lg font-semibold">
                    Tiada kenderaan tersedia untuk tarikh & masa yang dipilih.
                  </p>
                  <p class="text-gray-500 mt-2">
                    Sila cuba pilih julat masa lain atau semak semula tempahan sedia ada.
                  </p>
                <% else %>
                  <p class="text-gray-500 text-lg">
                    Tiada kenderaan tersedia dengan kriteria carian anda.
                  </p>
                <% end %>
              </div>
            <% end %>

            <div class="flex justify-center mt-6 space-x-2">
            <%= if @total > 0 and @total_pages > 1 do %>
              <div class="flex justify-center mt-6 space-x-2">
                <%= if @page > 1 do %>
                  <button phx-click="prev_page" class="px-3 py-1 bg-gray-300 rounded hover:bg-gray-400">Prev</button>
                <% end %>

                <span class="px-3 py-1">Page <%= @page %> of <%= @total_pages %></span>

                <%= if @page < @total_pages do %>
                  <button phx-click="next_page" class="px-3 py-1 bg-gray-300 rounded hover:bg-gray-400">Next</button>
                <% end %>
              </div>
            <% end %>
            </div>

            <!-- Modal -->
            <.modal :if={@live_action in [:new, :edit]} id="vehicle_booking-modal" show on_cancel={JS.patch(~p"/available_vehicles")}>
              <.live_component
                module={SpatoWeb.VehicleBookingLive.FormComponent}
                id={@vehicle_booking && @vehicle_booking.id || :new}
                title={@page_title}
                action={@live_action}
                vehicle_booking={@vehicle_booking}
                current_user={@current_user}
                patch={~p"/available_vehicles"}
                params={@params}
              />
            </.modal>
          </section>
        </main>
      </div>
    </div>
    """
  end
end

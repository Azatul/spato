defmodule SpatoWeb.AvailableVehicleLive do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Bookings

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
     |> assign(:total, 0)}
  end

  # Load vehicles based on filters and page
  defp load_vehicles(socket) do
    filters = socket.assigns.filters
    vehicles = Bookings.available_vehicles(filters)

    socket
    |> assign(:vehicles, vehicles)
    |> assign(:page, 1)
    |> assign(:total_pages, 1)
    |> assign(:total, length(vehicles))
  end


  @impl true
  def handle_event("search", params, socket) do
    # Handle both direct params and wrapped params
    filters = case params do
      %{"filters" => filters} -> filters
      filters when is_map(filters) -> filters
    end

    new_filters = %{
      "query" => Map.get(filters, "query", ""),
      "type" => Map.get(filters, "type", "all"),
      "capacity" => Map.get(filters, "capacity", ""),
      "pickup_time" => Map.get(filters, "pickup_time", nil),
      "return_time" => Map.get(filters, "return_time", nil)
    }

    {:noreply,
     socket
     |> assign(:filters, new_filters)
     |> assign(:form, to_form(new_filters))
     |> assign(:page, 1)
     |> load_vehicles()}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket), do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  @impl true
  def handle_params(params, _url, socket) do
    page =
      case Map.get(params, "page") do
        nil -> 1
        p when is_binary(p) ->
          case Integer.parse(p) do
            {num, _} -> num
            :error -> 1
          end
      end

    {:noreply,
     socket
     |> assign(:page, page)
     |> load_vehicles()}
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

            <!-- Filters -->
            <.form for={@form} phx-submit="search" class="mb-6 bg-white p-4 rounded-xl shadow-md">
              <div class="grid grid-cols-1 md:grid-cols-6 gap-4">
                <.input field={@form[:query]} placeholder="Cari mengikut nama atau nombor plat" />
                <.input field={@form[:type]} type="select" options={[
                  {"Semua", "all"},
                  {"SUV", "SUV"},
                  {"Van", "Van"},
                  {"Sedan", "Sedan"},
                  {"Pickup", "Pickup"},
                  {"Bas", "Bas"},
                  {"Motosikal", "Motosikal"}
                ]} />
                <.input field={@form[:capacity]} type="number" placeholder="Kapasiti minimum" />
                <.input field={@form[:pickup_time]} type="datetime-local" label="Masa Ambil" />
                <.input field={@form[:return_time]} type="datetime-local" label="Masa Pulang" />
                <.button class="bg-gray-900 text-white px-4 py-2 rounded-md hover:bg-gray-700">Cari</.button>
              </div>
            </.form>

            <!-- Vehicles grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              <%= for vehicle <- @vehicles do %>
                <div class="bg-white rounded-2xl shadow-md p-4 hover:shadow-lg transition-shadow">
                  <!-- Image with overlay badge -->
                  <div class="relative mb-3">
                    <img src={vehicle.photo_url || "/images/vehicle.jpg"} class="w-full h-40 object-cover rounded-lg" />
                    <!-- Vehicle Type badge overlaid on image -->
                    <div class="absolute top-2 right-2">
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

                  <!-- Vehicle Name -->
                  <h3 class="font-bold text-lg mb-1"><%= vehicle.name %></h3>

                  <!-- Plate Number -->
                  <p class="text-gray-600 mb-2"><%= vehicle.plate_number %></p>

                  <!-- Capacity -->
                  <p class="text-sm text-gray-500 mb-3"><%= vehicle.capacity %> penumpang</p>
                  <.link
                    navigate={
                      ~p"/vehicle_bookings/new?" <>
                        URI.encode_query(%{
                          vehicle_id: vehicle.id,
                          pickup_time: @filters["pickup_time"],
                          return_time: @filters["return_time"]
                        })
                    }
                    class="block"
                  >
                    <.button class="w-full bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
                      Tempah Sekarang
                    </.button>
                  </.link>
                </div>
              <% end %>
            </div>

            <!-- No vehicles message -->
            <%= if Enum.empty?(@vehicles) do %>
              <div class="text-center py-12">
                <p class="text-gray-500 text-lg">Tiada kenderaan tersedia dengan kriteria carian anda.</p>
              </div>
            <% end %>

            <!-- Pagination -->
            <%= if @total_pages > 1 do %>
              <div class="flex justify-center mt-8 space-x-2">
                <%= for p <- 1..@total_pages do %>
                  <.link patch={~p"/available_vehicles?page=#{p}"}
                    class={"px-3 py-1 rounded #{if @page == p, do: "bg-blue-500 text-white", else: "bg-gray-200 hover:bg-gray-300"}"}>
                    <%= p %>
                  </.link>
                <% end %>
              </div>
            <% end %>

              <!-- Modal -->
              <.modal :if={@live_action in [:new, :edit]} id="vehicle_booking-modal" show on_cancel={JS.patch(~p"/available_vehicles")}>
                <.live_component
                  module={SpatoWeb.VehicleBookingLive.FormComponent}
                  id={@vehicle_booking.id || :new}
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

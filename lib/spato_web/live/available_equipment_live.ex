defmodule SpatoWeb.AvailableEquipmentLive do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Bookings
  alias Spato.Bookings.EquipmentBooking

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    filters = %{
      "query" => "",
      "type" => "all",
      "quantity" => "",
      "usage_date" => nil,
      "return_date" => nil,
      "usage_time" => nil,
      "return_time" => nil
    }

    {:ok,
     socket
     |> assign(:page_title, "Peralatan Tersedia")
     |> assign(:active_tab, "equipments")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:equipments, [])
     |> assign(:filters, filters)
     |> assign(:form, to_form(filters))
     |> assign(:page, 1)
     |> assign(:total_pages, 1)
     |> assign(:total, 0)
     |> assign(:equipment_booking, nil)
     |> assign(:params, %{})
     |> assign(:live_action, :index)}
  end

  defp load_equipments(socket) do
    filters =
      socket.assigns.filters
      |> Map.put("page", socket.assigns.page)

    %{equipments_page: equipments, total: total, total_pages: total_pages, page: page} =
      Bookings.available_equipments(filters)

    socket
    |> assign(:equipments, equipments)
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
      "quantity" => Map.get(filters, "quantity", ""),
      "usage_date" => Map.get(filters, "usage_date", ""),
      "return_date" => Map.get(filters, "return_date", ""),
      "usage_time" => Map.get(filters, "usage_time", ""),
      "return_time" => Map.get(filters, "return_time", "")
    }

    {:noreply,
     socket
     |> assign(:filters, new_filters)
     |> assign(:form, to_form(filters))
     |> assign(:page, 1)
     |> load_equipments()}
  end

  @impl true
  def handle_event("next_page", _, socket) do
    if socket.assigns.page < socket.assigns.total_pages do
      {:noreply, socket |> assign(:page, socket.assigns.page + 1) |> load_equipments()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("prev_page", _, socket) do
    if socket.assigns.page > 1 do
      {:noreply, socket |> assign(:page, socket.assigns.page - 1) |> load_equipments()}
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
            equipment_booking = %EquipmentBooking{}

            socket
            |> assign(:live_action, :new)
            |> assign(:page_title, "Tambah Tempahan Peralatan")
            |> assign(:equipment_booking, equipment_booking)
            |> assign(:params, params)   # <-- store params here

          _ ->
            socket
            |> assign(:live_action, :index)
            |> assign(:equipment_booking, nil)
            |> assign(:params, %{})
        end

      {:noreply, socket |> load_equipments()}
    end

  @impl true
  def handle_info({SpatoWeb.EquipmentBookingLive.FormComponent, {:saved, _booking}}, socket) do
    {:noreply, socket |> load_equipments()}
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
            <h1 class="text-xl font-bold mb-1">Peralatan Tersedia</h1>
            <p class="text-md text-gray-500 mb-4">Cari dan tempah peralatan yang tersedia</p>

            <!-- Middle Section: Add Booking Button -->
            <section class="mb-4 flex justify-end">
              <.link patch={~p"/equipment_bookings"}>
                <.button class="bg-gray-900 text-white px-4 py-2 rounded-md hover:bg-gray-700">Lihat Senarai Tempahan</.button>
              </.link>
            </section>

            <!-- Filters -->
            <.form for={@form} phx-submit="search" class="mb-6 bg-white p-4 rounded-xl shadow-md w-full">
              <div class="flex flex-wrap items-end gap-4 w-full">

                <div class="flex-1 min-w-[150px]">
                  <.input
                    field={@form[:query]}
                    label="Carian"
                    placeholder="Cari peralatan, nombor siri..."
                    class="w-full"
                  />
                </div>

                <div class="flex flex-wrap items-end gap-4 min-w-0">
                  <.input
                    field={@form[:quantity]}
                    type="number"
                    label="Kuantiti"
                    placeholder="0"
                    class="w-32"
                  />

                  <.input
                    field={@form[:type]}
                    type="select"
                    label="Jenis"
                    options={[
                      {"Semua", "all"},
                      {"Laptop", "laptop"},
                      {"Projektor", "projector"},
                      {"Projektor Screen", "projector_screen"},
                      {"Printer", "printer"},
                      {"Kamera", "kamera"},
                      {"Speaker", "speaker"},
                      {"Laser Pointer", "laser_pointer"},
                      {"Extension Cord", "extension_cord"},
                      {"Whiteboard", "whiteboard"}
                    ]}
                    class="w-32"
                  />

                  <.input
                    field={@form[:usage_date]}
                    type="date"
                    label="Tarikh Guna"
                    class="w-44"
                  />

                  <.input
                    field={@form[:usage_time]}
                    type="time"
                    label="Masa Guna"
                    class="w-32"
                  />

                  <.input
                    field={@form[:return_date]}
                    type="date"
                    label="Tarikh Pulang"
                    class="w-44"
                  />

                  <.input
                    field={@form[:return_time]}
                    type="time"
                    label="Masa Pulang"
                    class="w-32"
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

            <!-- Equipments grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              <%= for equipment <- @equipments do %>
                <div class="bg-white rounded-2xl shadow-md p-4 hover:shadow-lg transition-shadow">
                  <div class="relative mb-3">
                    <img src={equipment.photo_url || "/images/equipment.jpg"} class="w-full h-40 object-cover rounded-lg" />
                  </div>

                  <h3 class="font-bold text-lg mb-1"><%= equipment.name %></h3>
                  <p class="text-gray-600 mb-2">SN: <%= equipment.serial_number %></p>
                  <p class="text-sm text-gray-500 mb-3"><%= equipment.quantity_available %> unit tersedia</p>

                  <%= if @filters["usage_date"] && @filters["return_date"] do %>
                    <.link
                      patch={
                        ~p"/available_equipments?#{%{
                          action: "new",
                          equipment_id: equipment.id,
                          usage_date: @filters["usage_date"],
                          return_date: @filters["return_date"],
                          usage_time: @filters["usage_time"],
                          return_time: @filters["return_time"]
                        }}"
                      }
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

            <%= if Enum.empty?(@equipments) do %>
              <div class="text-center py-12">
                <%= if @filters["usage_date"] != "" and @filters["return_date"] != "" do %>
                  <p class="text-red-500 text-lg font-semibold">
                    Tiada peralatan tersedia untuk tarikh & masa yang dipilih.
                  </p>
                  <p class="text-gray-500 mt-2">
                    Sila cuba pilih julat masa lain atau semak semula tempahan sedia ada.
                  </p>
                <% else %>
                  <p class="text-gray-500 text-lg">
                    Tiada peralatan tersedia dengan kriteria carian anda.
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

            <.modal :if={@live_action in [:new, :edit]} id="equipment_booking-modal" show on_cancel={JS.patch(~p"/available_equipments")}>
              <.live_component
                  module={SpatoWeb.EquipmentBookingLive.FormComponent}
                  id={@equipment_booking.id || :new}
                  title={@page_title}
                  action={@live_action}
                  equipment_booking={@equipment_booking}
                  equipment_id={@params["equipment_id"]}
                  usage_date={@params["usage_date"]}
                  usage_time={@params["usage_time"]}
                  return_date={@params["return_date"]}
                  return_time={@params["return_time"]}
                  current_user={@current_user}
                  patch={~p"/available_equipments"}
                />
            </.modal>
          </section>
        </main>
      </div>
    </div>
    """
  end
end

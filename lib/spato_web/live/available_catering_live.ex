defmodule SpatoWeb.AvailableCateringLive do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Bookings
  alias Spato.Bookings.CateringBooking

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    filters = %{
      "query" => "",
      "type" => "all",
      "date" => "",
    }

    {:ok,
     socket
     |> assign(:page_title, "Menu Katering Tersedia")
     |> assign(:active_tab, "catering")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:menus, [])
     |> assign(:filters, filters)
     |> assign(:form, to_form(filters))
     |> assign(:page, 1)
     |> assign(:total_pages, 1)
     |> assign(:total, 0)
     |> assign(:catering_booking, nil)
     |> assign(:params, %{})
     |> assign(:live_action, :index)}
  end

  defp load_menus(socket) do
    filters =
      socket.assigns.filters
      |> Map.put("page", socket.assigns.page)

    %{menus_page: menus, total: total, total_pages: total_pages, page: page} =
      Bookings.available_catering_menus(filters)

    socket
    |> assign(:menus, menus)
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
      "date" => Map.get(filters, "date", "")
    }

    {:noreply,
     push_patch(socket,
       to:
         ~p"/available_catering?#{%{
           query: new_filters["query"],
           type: new_filters["type"],
           date: new_filters["date"],
           page: 1
         }}"
     )}
  end

  @impl true
  def handle_event("next_page", _, socket) do
    if socket.assigns.page < socket.assigns.total_pages do
      new_page = socket.assigns.page + 1

      {:noreply,
       push_patch(socket,
         to:
           ~p"/available_catering?#{%{
             query: socket.assigns.filters["query"],
             type: socket.assigns.filters["type"],
             date: socket.assigns.filters["date"],
             page: new_page
           }}"
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("prev_page", _, socket) do
    if socket.assigns.page > 1 do
      new_page = socket.assigns.page - 1

      {:noreply,
       push_patch(socket,
         to:
           ~p"/available_catering?#{%{
             query: socket.assigns.filters["query"],
             type: socket.assigns.filters["type"],
             date: socket.assigns.filters["date"],
             page: new_page
           }}"
       )}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket),
    do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  @impl true
  def handle_params(params, _url, socket) do
    page =
      case Map.get(params, "page") do
        p when is_integer(p) -> p
        p when is_binary(p) ->
          case Integer.parse(p) do
            {v, _} -> v
            :error -> 1
          end
        _ -> 1
      end

    filters = %{
      "query" => Map.get(params, "query", ""),
      "type" => Map.get(params, "type", "all"),
      "date" => Map.get(params, "date", "")
    }

    socket =
      socket
      |> assign(:filters, filters)
      |> assign(:form, to_form(filters))
      |> assign(:page, if(page < 1, do: 1, else: page))
      |> assign(:params, params)

    socket =
      case params["action"] do
        "new" ->
          catering_booking = %CateringBooking{}

          socket
          |> assign(:live_action, :new)
          |> assign(:page_title, "Tambah Tempahan Katering")
          |> assign(:catering_booking, catering_booking)

        _ ->
          socket
          |> assign(:live_action, :index)
          |> assign(:catering_booking, nil)
      end

    {:noreply, socket |> load_menus()}
  end

  @impl true
  def handle_info({SpatoWeb.CateringBookingLive.FormComponent, {:saved, _booking}}, socket) do
    {:noreply, socket |> load_menus()}
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
            <h1 class="text-xl font-bold mb-1">Menu Katering Tersedia</h1>
            <p class="text-md text-gray-500 mb-4">Cari dan tempah menu katering yang tersedia</p>

            <!-- Middle Section: Add Catering Button -->
            <section class="mb-4 flex justify-end">
              <.link patch={~p"/catering_bookings"}>
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
                  placeholder="Cari menu, penerangan..."
                  class="w-full"
                />
              </div>

              <!-- Right inputs + button: fixed group -->
              <div class="flex flex-wrap items-end gap-4 min-w-0">
                <.input
                  field={@form[:type]}
                  type="select"
                  label="Jenis"
                  options={[
                    {"Sarapan", "sarapan"},
                    {"Makan Tengah Hari", "makan_tengahari"},
                    {"Makan Malam", "makan_malam"},
                    {"Minum Petang", "minum_petang"},
                    {"Minum Malam", "minum_malam"},
                    {"Minum Pagi", "minum_pagi"},
                    {"Semua", "all"}
                  ]}
                  class="w-40"
                />

                <.input
                  field={@form[:date]}
                  type="date"
                  label="Tarikh Tempahan"
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

            <!-- Menus grid -->
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
              <%= for menu <- @menus do %>
                <div class="bg-white rounded-2xl shadow-md p-4 hover:shadow-lg transition-shadow">
                  <div class="relative mb-3">
                    <img src={menu.photo_url || "/images/default-image.jpg"} class="w-full h-40 object-cover rounded-lg" />
                    <div class="absolute top-2 right-2">
                      <%= case menu.type do %>
                        <% "sarapan" -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-orange-500">Sarapan</span>
                        <% "makan_tengahari" -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-yellow-500">Makan Tengahari</span>
                        <% "makan_malam" -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-purple-500">Makan Malam</span>
                        <% "minum_petang" -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Minum Petang</span>
                        <% "minum_malam" -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-green-500">Minum Malam</span>
                        <% "minum_pagi" -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Minum Pagi</span>
                        <% "all" -> %><span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Semua</span>
                      <% end %>
                    </div>
                  </div>

                  <h3 class="font-bold text-lg mb-1"><%= menu.name %></h3>
                  <p class="text-gray-600 mb-2">RM <%= Decimal.to_string(menu.price_per_head, :normal) %></p>
                  <p class="text-sm text-gray-500 mb-3"><%= menu.description || "Tiada penerangan" %></p>

                <%= if @filters["date"] not in [nil, ""] do %>
                    <.link
                      patch={
                        ~p"/available_catering?#{%{
                          action: "new",
                          menu_id: menu.id,
                          query: @filters["query"],
                          type: @filters["type"],
                          date: @filters["date"],
                          page: @page
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
                      Pilih Tarikh Dahulu
                    </button>
                  <% end %>
                </div>
              <% end %>
            </div>

            <%= if Enum.empty?(@menus) do %>
              <div class="text-center py-12">
                <%= if @filters["date"] not in [nil, ""] do %>
                  <p class="text-red-500 text-lg font-semibold">
                    Tiada menu katering tersedia untuk tarikh yang dipilih.
                  </p>
                  <p class="text-gray-500 mt-2">
                    Sila cuba pilih tarikh lain atau semak semula tempahan sedia ada.
                  </p>
                <% else %>
                  <p class="text-gray-500 text-lg">
                    Tiada menu katering tersedia dengan kriteria carian anda.
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
            <.modal :if={@live_action in [:new, :edit]} id="catering_booking-modal" show on_cancel={JS.patch(~p"/available_catering?#{%{query: @filters["query"], type: @filters["type"], date: @filters["date"], page: @page}}") }>
              <.live_component
                module={SpatoWeb.CateringBookingLive.FormComponent}
                id={@catering_booking && @catering_booking.id || :new}
                title={@page_title}
                action={@live_action}
                catering_booking={@catering_booking}
                current_user={@current_user}
                patch={~p"/available_catering?#{%{query: @filters["query"], type: @filters["type"], date: @filters["date"], page: @page}}"}
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

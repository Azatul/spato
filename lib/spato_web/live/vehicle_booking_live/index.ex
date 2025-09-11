defmodule SpatoWeb.VehicleBookingLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Bookings
  alias Spato.Bookings.VehicleBooking

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, "vehicles")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:filter_status, "all")
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:filter_date, "")
     |> load_vehicle_bookings()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page   = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "q", "")
    status = Map.get(params, "status", "all")
    date   = Map.get(params, "date", "")

    socket =
      socket
      |> assign(:page, page)
      |> assign(:search_query, search)
      |> assign(:filter_status, status)
      |> assign(:filter_date, date)
      |> load_vehicle_bookings()

    # Block editing if not pending or not owner
    socket =
      case socket.assigns.live_action do
        :edit ->
          id = Map.get(params, "id")
          booking = Bookings.get_vehicle_booking!(id)

          if booking.status == "pending" and booking.user_id == socket.assigns.current_user.id do
            apply_action(socket, :edit, params)
          else
            socket
            |> put_flash(:error, "Anda tidak boleh mengemaskini tempahan ini.")
            |> push_patch(to: ~p"/vehicle_bookings")
          end

        _ ->
          apply_action(socket, socket.assigns.live_action, params)
      end

    {:noreply, socket}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Kemaskini Tempahan Kenderaan")
    |> assign(:vehicle_booking, Bookings.get_vehicle_booking!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Tambah Tempahan Kenderaan")
    |> assign(:vehicle_booking, %VehicleBooking{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Senarai Tempahan Kenderaan")
    |> assign(:vehicle_booking, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Tempahan Kenderaan")
    |> assign(:vehicle_booking, Bookings.get_vehicle_booking!(id))
  end

  @impl true
  def handle_info({SpatoWeb.VehicleBookingLive.FormComponent, {:saved, _vehicle_booking}}, socket) do
    {:noreply, load_vehicle_bookings(socket)}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 1)
     |> load_vehicle_bookings()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
      push_patch(socket,
        to: ~p"/vehicle_bookings?page=1&q=#{socket.assigns.search_query}&status=#{status}")}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, String.to_integer(page))
     |> load_vehicle_bookings()}
  end

  @impl true
  def handle_event("filter_date", %{"date" => date}, socket) do
    {:noreply,
    push_patch(socket,
      to: ~p"/vehicle_bookings?page=1&q=#{socket.assigns.search_query}&status=#{socket.assigns.filter_status}&date=#{date}"
    )}
  end

  @impl true
  def handle_event("cancel", %{"id" => id}, socket) do
    booking = Bookings.get_vehicle_booking!(id)

    case Bookings.cancel_booking(booking, socket.assigns.current_user) do
      {:ok, _} ->
        {:noreply, load_vehicle_bookings(socket)}

      {:error, :not_allowed} ->
        {:noreply, socket |> put_flash(:error, "Tidak boleh batal selepas tindakan admin.")}
    end
  end

  # --- LOAD BOOKINGS ---
  defp load_vehicle_bookings(socket) do
    params = %{
      "page" => socket.assigns.page,
      "search" => socket.assigns.search_query,
      "status" => socket.assigns.filter_status,
      "date" => socket.assigns.filter_date
    }

    data = Bookings.list_vehicle_bookings_paginated(params, socket.assigns.current_user)

    socket
    |> assign(:vehicle_bookings_page, data.vehicle_bookings_page)
    |> assign(:total_pages, data.total_pages)
    |> assign(:filtered_count, data.total)
    |> assign(:page, data.page)
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
            <h1 class="text-xl font-bold mb-1">Tempahan Kenderaan Saya</h1>
            <p class="text-md text-gray-500 mb-4">Semak semua tempahan kenderaan yang anda buat</p>



            <!-- Booking Table Section -->
            <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
              <div class="flex flex-col mb-4 gap-2">
                <div class="flex items-center justify-between">
                  <h2 class="text-lg font-semibold text-gray-900">Senarai Tempahan Kenderaan</h2>
                  <.link patch={~p"/vehicle_bookings/new"}>
                    <.button>Tambah Tempahan Kenderaan</.button>
                  </.link>
                </div>

                <div class="flex flex-wrap gap-2 mt-2">
                  <!-- Search -->
                  <form phx-change="search" class="flex-1 min-w-[200px]">
                    <input type="text" name="q" value={@search_query} placeholder="Cari tujuan, destinasi..." class="w-full border rounded-md px-2 py-1 text-sm"/>
                  </form>

                  <!-- Status filter -->
                  <form phx-change="filter_status">
                    <select name="status" class="border rounded-md px-2 py-1 text-sm">
                      <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                      <option value="pending" selected={@filter_status == "pending"}>Menunggu</option>
                      <option value="approved" selected={@filter_status == "approved"}>Diluluskan</option>
                      <option value="rejected" selected={@filter_status == "rejected"}>Ditolak</option>
                      <option value="completed" selected={@filter_status == "completed"}>Selesai</option>
                    </select>
                  </form>

                  <!-- Date filter -->
                  <form phx-change="filter_date">
                    <input type="date" name="date" value={@filter_date} class="border rounded-md px-2 py-1 text-sm"/>
                  </form>
                </div>
              </div>

              <div class="mb-2 text-sm text-gray-600">
                <%= if @filtered_count == 0 do %>
                  Tiada tempahan ditemui
                <% else %>
                  <%= @filtered_count %> tempahan ditemui
                <% end %>
              </div>

              <.table
                id="vehicle_bookings"
                rows={@vehicle_bookings_page}
                row_click={fn vehicle_booking -> JS.patch(
                  ~p"/vehicle_bookings/#{vehicle_booking.id}?action=show&page=#{@page}&q=#{@search_query}&status=#{@filter_status}"
                ) end}
              >
                <:col :let={vehicle_booking} label="ID"><%= vehicle_booking.id %></:col>
                <:col :let={vehicle_booking} label="Tujuan">{vehicle_booking.purpose}</:col>
                <:col :let={vehicle_booking} label="Destinasi Perjalanan">{vehicle_booking.trip_destination}</:col>
                <:col :let={vehicle_booking} label="Masa Pickup">{vehicle_booking.pickup_time}</:col>
                <:col :let={vehicle_booking} label="Masa Pulang">{vehicle_booking.return_time}</:col>
                <:col :let={vehicle_booking} label="Status">{vehicle_booking.status}</:col>
                <:col :let={vehicle_booking} label="Catatan Tambahan">{vehicle_booking.additional_notes}</:col>
                <:action :let={vehicle_booking}>
                  <%= if vehicle_booking.status == "pending" do %>
                    <.link phx-click={JS.push("cancel", value: %{id: vehicle_booking.id})} data-confirm="Batal tempahan?">
                      Batal
                    </.link>
                  <% else %>
                    <span class="text-gray-400">—</span>
                  <% end %>
                </:action>
              </.table>

              <!-- Pagination -->
              <%= if @filtered_count > 1 do %>
                <div class="relative flex items-center mt-4">
                  <!-- Previous button -->
                  <div class="flex-1">
                    <.link
                      patch={~p"/vehicle_bookings?page=#{max(@page - 1, 1)}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                      class={"px-3 py-1 border rounded " <>
                        if @page == 1,
                          do: "bg-gray-200 text-gray-500 cursor-not-allowed",
                          else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Sebelumnya
                    </.link>
                  </div>

                  <!-- Page numbers -->
                  <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
                    <%= for p <- 1..@total_pages do %>
                      <.link
                        patch={~p"/vehicle_bookings?page=#{p}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                        class={"px-3 py-1 border rounded " <>
                          if p == @page,
                            do: "bg-gray-700 text-white",
                            else: "bg-white text-gray-700 hover:bg-gray-100"}>
                        <%= p %>
                      </.link>
                    <% end %>
                  </div>

                  <!-- Next button -->
                  <div class="flex-1 text-right">
                    <.link
                      patch={~p"/vehicle_bookings?page=#{min(@page + 1, @total_pages)}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                      class={"px-3 py-1 border rounded " <>
                        if @page == @total_pages,
                          do: "bg-gray-200 text-gray-500 cursor-not-allowed",
                          else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Seterusnya
                    </.link>
                  </div>
                </div>
              <% end %>

              <!-- Modal -->
              <.modal :if={@live_action in [:new, :edit]} id="vehicle_booking-modal" show on_cancel={JS.patch(~p"/vehicle_bookings")}>
                <.live_component
                  module={SpatoWeb.VehicleBookingLive.FormComponent}
                  id={@vehicle_booking.id || :new}
                  title={@page_title}
                  action={@live_action}
                  vehicle_booking={@vehicle_booking}
                  current_user={@current_user}
                  patch={~p"/vehicle_bookings"}
                />
              </.modal>

              <!-- Modal -->
              <.modal
                :if={@live_action == :show}
                id="vehicle-booking-show-modal"
                show
                on_cancel={JS.patch(~p"/vehicle_bookings?page=#{@page}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}")}>
                <.live_component
                  module={SpatoWeb.VehicleBookingLive.ShowComponent}
                  id={@vehicle_booking.id}
                  vehicle_booking={@vehicle_booking}
                />
              </.modal>
            </section>
          </section>
        </main>
      </div>
    </div>
    """
  end
end

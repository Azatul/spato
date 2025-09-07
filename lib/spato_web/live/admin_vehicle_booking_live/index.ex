defmodule SpatoWeb.AdminVehicleBookingLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Bookings
  alias Spato.Repo

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    # Calculate booking statistics
    stats = calculate_booking_stats()

    {:ok,
     socket
     |> assign(:page_title, "Senarai Tempahan Kenderaan")
     |> assign(:active_tab, "vehicles")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:page, 1)
     |> assign(:total_pages, 1)
     |> assign(:filtered_count, 0)
     |> assign(:search_query, "")
     |> assign(:filter_status, "all")
     |> assign(:booking_date, "")
     |> assign(:stats, stats)
     |> stream(:vehicle_bookings, [])}
  end

  # Calculate booking statistics
  defp calculate_booking_stats do
    now = DateTime.utc_now()
    week_start = DateTime.add(now, -7, :day)
    month_start = DateTime.add(now, -30, :day)

    # Weekly booking activity (all statuses)
    weekly_bookings = Bookings.list_vehicle_bookings()
    |> Enum.filter(fn booking ->
      DateTime.compare(booking.inserted_at, week_start) == :gt
    end)

    # Monthly completed bookings
    monthly_completed = Bookings.list_vehicle_bookings()
    |> Enum.filter(fn booking ->
      booking.status == "completed" and DateTime.compare(booking.inserted_at, month_start) == :gt
    end)

    # Pending approval bookings
    pending_bookings = Bookings.list_vehicle_bookings()
    |> Enum.filter(fn booking -> booking.status == "pending" end)

    %{
      weekly_activity: length(weekly_bookings),
      monthly_completed: length(monthly_completed),
      pending_approval: length(pending_bookings)
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    %{vehicle_bookings_page: bookings, total: total, total_pages: total_pages, page: page} =
      Bookings.list_vehicle_bookings_paginated(%{
        "page" => Map.get(params, "page", "1"),
        "search" => Map.get(params, "q", ""),
        "status" => Map.get(params, "status", "all"),
        "booking_date" => Map.get(params, "booking_date", "")
      })

    socket =
      socket
      |> assign(:page, page)
      |> assign(:total_pages, total_pages)
      |> assign(:filtered_count, total)
      |> assign(:search_query, Map.get(params, "q", ""))
      |> assign(:filter_status, Map.get(params, "status", "all"))
      |> assign(:booking_date, Map.get(params, "booking_date", ""))
      |> stream(:vehicle_bookings, bookings, reset: true)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Senarai Tempahan Kenderaan")
    |> assign(:vehicle_booking, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    vehicle_booking = Bookings.get_vehicle_booking!(id)
    |> Repo.preload([:user, :vehicle, :approved_by_user, :cancelled_by_user])

    socket
    |> assign(:page_title, "Show Vehicle booking")
    |> assign(:vehicle_booking, vehicle_booking)
  end

  @impl true
  def handle_info({SpatoWeb.AdminVehicleBookingLive.FormComponent, {:saved, vehicle_booking}}, socket) do
    {:noreply, stream_insert(socket, :vehicle_bookings, vehicle_booking)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket), do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/admin/vehicle_bookings?page=1&q=#{query}&status=#{socket.assigns.filter_status}&booking_date=#{socket.assigns.booking_date}"
     )}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/admin/vehicle_bookings?page=1&q=#{socket.assigns.search_query}&status=#{status}&booking_date=#{socket.assigns.booking_date}"
     )}
  end

  @impl true
  def handle_event("filter_date", %{"booking_date" => booking_date}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/admin/vehicle_bookings?page=1&q=#{socket.assigns.search_query}&status=#{socket.assigns.filter_status}&booking_date=#{booking_date}"
     )}
  end

  @impl true
def handle_event("approve", %{"id" => id}, socket) do
  vehicle_booking = Bookings.get_vehicle_booking!(id)
  {:ok, updated} = Bookings.update_vehicle_booking(vehicle_booking, %{
    status: "approved",
    approved_by_user_id: socket.assigns.current_user.id
  })
  {:noreply, stream_insert(socket, :vehicle_bookings, updated)}
end

def handle_event("reject", %{"id" => id}, socket) do
  vehicle_booking = Bookings.get_vehicle_booking!(id)
  {:ok, updated} = Bookings.update_vehicle_booking(vehicle_booking, %{
    status: "rejected",
    approved_by_user_id: socket.assigns.current_user.id
  })
  {:noreply, stream_insert(socket, :vehicle_bookings, updated)}
end

def handle_event("complete", %{"id" => id}, socket) do
  vehicle_booking = Bookings.get_vehicle_booking!(id)
  {:ok, updated} = Bookings.update_vehicle_booking(vehicle_booking, %{status: "completed"})
  {:noreply, stream_insert(socket, :vehicle_bookings, updated)}
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
            <h1 class="text-xl font-bold mb-1">Senarai Tempahan Kenderaan</h1>
            <p class="text-md text-gray-500 mb-4">Semak dan urus tempahan kenderaan</p>

            <!-- Stats Cards -->
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
              <%= for {label, value, color} <- [
                {"Aktiviti Tempahan Minggu Ini", @stats.weekly_activity, "text-blue-500"},
                {"Tempahan Selesai Bulan Ini", @stats.monthly_completed, "text-green-500"},
                {"Menunggu Kelulusan", @stats.pending_approval, "text-yellow-500"}
              ] do %>
                <div class="bg-white p-4 rounded-xl shadow-md flex flex-col justify-between h-30 transition-transform hover:scale-105">
                  <div>
                    <p class="text-sm text-gray-500"><%= label %></p>
                    <p class={"text-3xl font-bold mt-1 #{color}"}><%= value %></p>
                  </div>
                </div>
              <% end %>
            </div>

            <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
              <!-- Header: Search + Filter -->
              <div class="flex flex-col mb-4 gap-2">
                <div class="flex items-center justify-between">
                  <h2 class="text-lg font-semibold text-gray-900">Senarai Tempahan Kenderaan</h2>
                </div>

                <!-- Search and Filter -->
                <div class="flex flex-wrap gap-2 mt-2">
                  <form phx-change="search" class="flex-1 min-w-[200px]">
                    <input type="text" name="q" value={@search_query} placeholder="Cari kenderaan, pengguna, tujuan atau destinasi..." class="w-full border rounded-md px-2 py-1 text-sm"/>
                  </form>

                  <!-- Filter by booking date -->
                  <form phx-change="filter_date">
                    <input type="date" name="booking_date" value={@booking_date} class="border rounded-md px-2 py-1 text-sm"/>
                  </form>

                  <!-- Filter by status -->
                  <form phx-change="filter_status">
                    <select name="status" class="border rounded-md px-2 pr-8 py-1 text-sm">
                      <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                      <option value="pending" selected={@filter_status == "pending"}>Menunggu</option>
                      <option value="approved" selected={@filter_status == "approved"}>Diluluskan</option>
                      <option value="rejected" selected={@filter_status == "rejected"}>Ditolak</option>
                      <option value="cancelled" selected={@filter_status == "cancelled"}>Dibatalkan</option>
                      <option value="completed" selected={@filter_status == "completed"}>Selesai</option>
                    </select>
                  </form>
                </div>
              </div>

              <!-- Bookings count message -->
              <div class="mb-2 text-sm text-gray-600">
                <%= if @filtered_count == 0 do %>
                  Tiada tempahan ditemui
                <% else %>
                  <%= @filtered_count %> tempahan ditemui
                <% end %>
              </div>
              <.table
                id="vehicle_bookings"
                rows={@streams.vehicle_bookings}
                row_click={fn {_id, vehicle_booking} ->
                  JS.patch(
                    ~p"/admin/vehicle_bookings/#{vehicle_booking.id}?action=show"
                  )
                end}
              >
                <:col :let={{_id, vehicle_booking}} label="Pengguna">
                  <%= if vehicle_booking.user do %>
                    <%= vehicle_booking.user.email %>
                  <% else %>
                    N/A
                  <% end %>
                </:col>
                <:col :let={{_id, vehicle_booking}} label="Kenderaan">
                  <%= if vehicle_booking.vehicle do %>
                    <%= vehicle_booking.vehicle.name %> (<%= vehicle_booking.vehicle.plate_number %>)
                  <% else %>
                    N/A
                  <% end %>
                </:col>
                <:col :let={{_id, vehicle_booking}} label="Tujuan">{vehicle_booking.purpose}</:col>
                <:col :let={{_id, vehicle_booking}} label="Destinasi">{vehicle_booking.trip_destination}</:col>
                <:col :let={{_id, vehicle_booking}} label="Masa Ambil">
                  <%= Calendar.strftime(vehicle_booking.pickup_time, "%d/%m/%Y %H:%M") %>
                </:col>
                <:col :let={{_id, vehicle_booking}} label="Masa Pulang">
                  <%= Calendar.strftime(vehicle_booking.return_time, "%d/%m/%Y %H:%M") %>
                </:col>
                <:col :let={{_id, vehicle_booking}} label="Status">
                  <span class={
                    case vehicle_booking.status do
                      "approved" -> "text-green-600 font-bold"
                      "rejected" -> "text-red-600 font-bold"
                      "pending" -> "text-yellow-600 font-bold"
                      "cancelled" -> "text-gray-600 font-bold"
                      "completed" -> "text-blue-600 font-bold"
                      _ -> "text-gray-600"
                    end
                  }>
                    <%= case vehicle_booking.status do
                      "approved" -> "Diluluskan"
                      "rejected" -> "Ditolak"
                      "pending" -> "Menunggu"
                      "cancelled" -> "Dibatalkan"
                      "completed" -> "Selesai"
                      _ -> String.capitalize(vehicle_booking.status)
                    end %>
                  </span>
                </:col>
                <:col :let={{_id, vehicle_booking}} label="Nota Tambahan">{vehicle_booking.additional_notes}</:col>
                <:col :let={{_id, vehicle_booking}} label="Sebab Penolakan">{vehicle_booking.rejection_reason}</:col>
                <:action :let={{_id, vehicle_booking}}>
                  <div class="sr-only">
                    <.link navigate={~p"/admin/vehicle_bookings/#{vehicle_booking}"}>Show</.link>
                  </div>
                </:action>
                <:action :let={{_id, vehicle_booking}}>
                  <%= if vehicle_booking.status == "pending" do %>
                    <.link
                      phx-click={JS.push("approve", value: %{id: vehicle_booking.id})}
                      class="text-green-600"
                    >
                      Luluskan
                    </.link>
                    <.link
                      phx-click={JS.push("reject", value: %{id: vehicle_booking.id})}
                      class="text-red-600 ml-2"
                    >
                      Tolak
                    </.link>
                  <% else %>
                    <%= if vehicle_booking.status == "approved" do %>
                      <.link
                        phx-click={JS.push("complete", value: %{id: vehicle_booking.id})}
                        class="text-blue-600"
                      >
                        Selesai
                      </.link>
                    <% else %>
                      <span class="text-gray-500">
                        <%= case vehicle_booking.status do
                          "approved" -> "Diluluskan"
                          "rejected" -> "Ditolak"
                          "cancelled" -> "Dibatalkan"
                          "completed" -> "Selesai"
                          _ -> String.capitalize(vehicle_booking.status)
                        end %>
                      </span>
                    <% end %>
                  <% end %>
                </:action>

              </.table>

              <!-- Pagination -->
              <%= if @filtered_count > 0 do %>
              <div class="relative flex items-center mt-4">
                <!-- Previous button -->
                <div class="flex-1">
                  <.link
                    patch={~p"/admin/vehicle_bookings?page=#{max(@page - 1, 1)}&q=#{@search_query}&status=#{@filter_status}&booking_date=#{@booking_date}"}
                    class={"px-3 py-1 border rounded #{if @page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
                  >
                    Sebelumnya
                  </.link>
                </div>

                <!-- Page numbers (centered) -->
                <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
                  <%= for p <- 1..@total_pages do %>
                    <.link
                      patch={~p"/admin/vehicle_bookings?page=#{p}&q=#{@search_query}&status=#{@filter_status}&booking_date=#{@booking_date}"}
                      class={"px-3 py-1 border rounded #{if p == @page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
                    >
                      <%= p %>
                    </.link>
                  <% end %>
                </div>

                <!-- Next button -->
                <div class="flex-1 text-right">
                  <.link
                    patch={~p"/admin/vehicle_bookings?page=#{min(@page + 1, @total_pages)}&q=#{@search_query}&status=#{@filter_status}&booking_date=#{@booking_date}"}
                    class={"px-3 py-1 border rounded #{if @page == @total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
                  >
                    Seterusnya
                  </.link>
                </div>
              </div>
              <% end %>
            </section>

            <.modal :if={@live_action == :show} id="admin-vehicle-booking-show-modal" show on_cancel={JS.patch(~p"/admin/vehicle_bookings")}>
              <.live_component
                module={SpatoWeb.AdminVehicleBookingLive.ShowComponent}
                id={@vehicle_booking.id}
                vehicle_booking={@vehicle_booking}
              />
            </.modal>

          </section>
        </main>
      </div>
    </div>
    """
  end
end

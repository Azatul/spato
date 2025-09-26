defmodule SpatoWeb.HistoryLive.BookingHistoryLive do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Bookings

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:active_tab, "history")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, current_user)
     |> assign(:selected_table, :meeting_room) # default tab
     |> assign(:equipment_history, list_closed(:equipment, current_user))
     |> assign(:room_history, list_closed(:meeting_room, current_user))
     |> assign(:vehicle_history, list_closed(:vehicle, current_user))
     |> assign(:catering_history, list_closed(:catering, current_user))
     |> assign(:search_query, "")
     |> assign(:filter_status, "all")
     |> assign(:filter_date, "")
     |> assign(:equipment_page, 1)
     |> assign(:room_page, 1)
     |> assign(:vehicle_page, 1)
     |> assign(:catering_page, 1)
     |> init_filtered_lists()
     |> init_paginated_lists()}
  end

  @impl true
  def handle_event("switch_table", %{"table" => table}, socket) do
    {:noreply, assign(socket, :selected_table, String.to_existing_atom(table))}
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  # --- history filters ---
  def handle_event("history_search", %{"q" => q}, socket) do
    socket = socket |> assign(:search_query, q)
    socket = reset_selected_page(socket)
    socket = apply_filters_for_selected(socket)
    {:noreply, recompute_selected_pagination(socket)}
  end

  def handle_event("history_filter_status", %{"status" => status}, socket) do
    socket = socket |> assign(:filter_status, status)
    socket = reset_selected_page(socket)
    socket = apply_filters_for_selected(socket)
    {:noreply, recompute_selected_pagination(socket)}
  end

  def handle_event("history_filter_date", %{"date" => date}, socket) do
    socket = socket |> assign(:filter_date, date)
    socket = reset_selected_page(socket)
    socket = apply_filters_for_selected(socket)
    {:noreply, recompute_selected_pagination(socket)}
  end

  @impl true
  def handle_event("paginate_history", %{"page" => page_str}, socket) do
    page = String.to_integer(page_str)

    socket =
      case socket.assigns.selected_table do
        :equipment -> assign(socket, :equipment_page, page)
        :meeting_room -> assign(socket, :room_page, page)
        :vehicle -> assign(socket, :vehicle_page, page)
        :catering -> assign(socket, :catering_page, page)
      end

    {:noreply, recompute_selected_pagination(socket)}
  end

  # --- helper
  defp list_closed(:equipment, user) do
    Bookings.list_closed_equipment_bookings(user)
  end

  defp list_closed(:meeting_room, user) do
    Bookings.list_closed_room_bookings(user)
  end

  defp list_closed(:vehicle, user) do
    Bookings.list_closed_vehicle_bookings(user)
  end

  defp list_closed(:catering, user) do
    Bookings.list_closed_catering_bookings(user)
  end

  defp init_filtered_lists(socket) do
    socket
    |> assign(:equipment_history_filtered,
      filter_equipment_history(socket.assigns.equipment_history, socket.assigns.search_query, socket.assigns.filter_status, socket.assigns.filter_date)
    )
    |> assign(:room_history_filtered,
      filter_room_history(socket.assigns.room_history, socket.assigns.search_query, socket.assigns.filter_status, socket.assigns.filter_date)
    )
    |> assign(:vehicle_history_filtered,
      filter_vehicle_history(socket.assigns.vehicle_history, socket.assigns.search_query, socket.assigns.filter_status, socket.assigns.filter_date)
    )
    |> assign(:catering_history_filtered,
      filter_catering_history(socket.assigns.catering_history, socket.assigns.search_query, socket.assigns.filter_status, socket.assigns.filter_date)
    )
  end

  defp init_paginated_lists(socket) do
    socket
    |> recompute_pagination_for(:equipment)
    |> recompute_pagination_for(:meeting_room)
    |> recompute_pagination_for(:vehicle)
    |> recompute_pagination_for(:catering)
  end

  defp apply_filters_for_selected(socket) do
    case socket.assigns.selected_table do
      :equipment ->
        assign(socket, :equipment_history_filtered,
          filter_equipment_history(socket.assigns.equipment_history, socket.assigns.search_query, socket.assigns.filter_status, socket.assigns.filter_date)
        )

      :meeting_room ->
        assign(socket, :room_history_filtered,
          filter_room_history(socket.assigns.room_history, socket.assigns.search_query, socket.assigns.filter_status, socket.assigns.filter_date)
        )

      :vehicle ->
        assign(socket, :vehicle_history_filtered,
          filter_vehicle_history(socket.assigns.vehicle_history, socket.assigns.search_query, socket.assigns.filter_status, socket.assigns.filter_date)
        )

      :catering ->
        assign(socket, :catering_history_filtered,
          filter_catering_history(socket.assigns.catering_history, socket.assigns.search_query, socket.assigns.filter_status, socket.assigns.filter_date)
        )
    end
  end

  defp reset_selected_page(socket) do
    case socket.assigns.selected_table do
      :equipment -> assign(socket, :equipment_page, 1)
      :meeting_room -> assign(socket, :room_page, 1)
      :vehicle -> assign(socket, :vehicle_page, 1)
      :catering -> assign(socket, :catering_page, 1)
    end
  end

  defp recompute_selected_pagination(socket) do
    case socket.assigns.selected_table do
      :equipment -> recompute_pagination_for(socket, :equipment)
      :meeting_room -> recompute_pagination_for(socket, :meeting_room)
      :vehicle -> recompute_pagination_for(socket, :vehicle)
      :catering -> recompute_pagination_for(socket, :catering)
    end
  end

  defp recompute_pagination_for(socket, :equipment) do
    paginate_and_assign(socket, :equipment_history_filtered, :equipment_history_page, :equipment_filtered_count, :equipment_total_pages, socket.assigns.equipment_page)
  end
  defp recompute_pagination_for(socket, :meeting_room) do
    paginate_and_assign(socket, :room_history_filtered, :room_history_page, :room_filtered_count, :room_total_pages, socket.assigns.room_page)
  end
  defp recompute_pagination_for(socket, :vehicle) do
    paginate_and_assign(socket, :vehicle_history_filtered, :vehicle_history_page, :vehicle_filtered_count, :vehicle_total_pages, socket.assigns.vehicle_page)
  end
  defp recompute_pagination_for(socket, :catering) do
    paginate_and_assign(socket, :catering_history_filtered, :catering_history_page, :catering_filtered_count, :catering_total_pages, socket.assigns.catering_page)
  end

  defp paginate_and_assign(socket, filtered_key, page_key, count_key, total_pages_key, page) do
    list = Map.fetch!(socket.assigns, filtered_key)
    per_page = 10
    total = length(list)
    total_pages = max(1, div(total + per_page - 1, per_page))
    current_page = min(max(page, 1), total_pages)
    start_index = (current_page - 1) * per_page
    page_list = Enum.slice(list, start_index, per_page)

    socket
    |> assign(page_key, page_list)
    |> assign(count_key, total)
    |> assign(total_pages_key, total_pages)
    |> case do
      s when filtered_key == :equipment_history_filtered -> assign(s, :equipment_page, current_page)
      s when filtered_key == :room_history_filtered -> assign(s, :room_page, current_page)
      s when filtered_key == :vehicle_history_filtered -> assign(s, :vehicle_page, current_page)
      s when filtered_key == :catering_history_filtered -> assign(s, :catering_page, current_page)
    end
  end

  # --- filtering helpers ---
  defp filter_by_status(list, "all"), do: list
  defp filter_by_status(list, status), do: Enum.filter(list, &(&1.status == status))

  defp parse_iso_date("") , do: nil
  defp parse_iso_date(nil), do: nil
  defp parse_iso_date(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, d} -> d
      _ -> nil
    end
  end

  defp filter_equipment_history(list, q, status, date_str) do
    d = parse_iso_date(date_str)
    list
    |> filter_by_status(status)
    |> Enum.filter(fn b ->
      cond do
        is_nil(d) -> true
        true -> Date.compare(DateTime.to_date(b.usage_at), d) == :eq or Date.compare(DateTime.to_date(b.return_at), d) == :eq
      end
    end)
    |> filter_by_query(q, fn b ->
      [b.location, b.status, (b.equipment && b.equipment.name), (b.equipment && b.equipment.serial_number), b.additional_notes]
    end)
  end

  defp filter_room_history(list, q, status, date_str) do
    d = parse_iso_date(date_str)
    list
    |> filter_by_status(status)
    |> Enum.filter(fn b ->
      cond do
        is_nil(d) -> true
        true -> Date.compare(DateTime.to_date(b.start_time), d) == :eq or Date.compare(DateTime.to_date(b.end_time), d) == :eq
      end
    end)
    |> filter_by_query(q, fn b ->
      [b.purpose, b.status, (b.meeting_room && b.meeting_room.name), (b.meeting_room && b.meeting_room.location), b.notes]
    end)
  end

  defp filter_vehicle_history(list, q, status, date_str) do
    d = parse_iso_date(date_str)
    list
    |> filter_by_status(status)
    |> Enum.filter(fn b ->
      cond do
        is_nil(d) -> true
        true -> Date.compare(DateTime.to_date(b.pickup_time), d) == :eq or Date.compare(DateTime.to_date(b.return_time), d) == :eq
      end
    end)
    |> filter_by_query(q, fn b ->
      [b.purpose, b.trip_destination, b.status, (b.vehicle && b.vehicle.name), (b.vehicle && b.vehicle.plate_number), b.additional_notes]
    end)
  end

  defp filter_catering_history(list, q, status, date_str) do
    d = parse_iso_date(date_str)
    list
    |> filter_by_status(status)
    |> Enum.filter(fn b ->
      cond do
        is_nil(d) -> true
        true -> Date.compare(b.date, d) == :eq
      end
    end)
    |> filter_by_query(q, fn b ->
      [b.location, b.special_request, b.status, (b.menu && b.menu.name), (b.menu && b.menu.description)]
    end)
  end

  defp filter_by_query(list, q, projector_fun) do
    trimmed = String.trim(to_string(q || ""))
    if trimmed == "" do
      list
    else
      like = String.downcase(trimmed)
      Enum.filter(list, fn b ->
        projector_fun.(b)
        |> Enum.map(&to_string(&1 || ""))
        |> Enum.any?(fn s -> String.contains?(String.downcase(s), like) end)
      end)
    end
  end

@impl true
def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>

      <div class="flex flex-col flex-1">
        <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title="Sejarah Tempahan" />

        <main class="flex-1 overflow-y-auto pt-20 p-6 bg-gray-100">
          <h1 class="text-xl font-bold mb-4">Sejarah Tempahan Anda</h1>

          <!-- Tabs -->
          <div class="flex gap-4 mb-6">
            <%= for {label, key} <- [
                  {"Bilik Mesyuarat", :meeting_room},
                  {"Kenderaan", :vehicle},
                  {"Katering", :catering},
                  {"Peralatan", :equipment}
                ] do %>
              <button
                phx-click="switch_table"
                phx-value-table={key}
                class={"px-4 py-2 rounded-md border " <>
                  if @selected_table == key, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                <%= label %>
              </button>
            <% end %>
          </div>

          <!-- Equipment Table -->
          <%= if @selected_table == :equipment do %>
            <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
              <div class="flex flex-col mb-4 gap-2">
                <div class="flex items-center justify-between">
                  <h2 class="text-lg font-semibold text-gray-900">Sejarah Tempahan Peralatan</h2>
                </div>

                <div class="flex flex-wrap gap-2 mt-2">
                  <form phx-change="history_search" class="flex-1 min-w-[200px]">
                    <input type="text" name="q" value={@search_query} placeholder="Cari lokasi, catatan..." class="w-full border rounded-md px-2 py-1 text-sm"/>
                  </form>
                  <form phx-change="history_filter_status">
                    <select name="status" class="border rounded-md px-2 pr-8 py-1 text-sm">
                      <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                      <option value="rejected" selected={@filter_status == "rejected"}>Ditolak</option>
                      <option value="completed" selected={@filter_status == "completed"}>Selesai</option>
                      <option value="cancelled" selected={@filter_status == "cancelled"}>Dibatalkan</option>
                    </select>
                  </form>
                  <form phx-change="history_filter_date">
                    <input type="date" name="date" value={@filter_date} class="border rounded-md px-2 py-1 text-sm"/>
                  </form>
                </div>
              </div>

              <!-- Count -->
              <div class="mb-2 text-sm text-gray-600">
                <%= if @equipment_filtered_count == 0 do %>
                  Tiada tempahan ditemui
                <% else %>
                  <%= @equipment_filtered_count %> tempahan ditemui
                <% end %>
              </div>

              <.table id="equipment_history" rows={@equipment_history_page}>
              <:col :let={booking} label="ID"><%= booking.id %></:col>
              <:col :let={booking} label="Peralatan">
                <%= if booking.equipment do %>
                  <div class="flex flex-col">
                    <div class="font-semibold text-gray-900"><%= booking.equipment.name %></div>
                    <div class="text-sm text-gray-500">No. Siri: <%= booking.equipment.serial_number %></div>
                  </div>
                <% else %>
                  <span class="text-gray-400">—</span>
                <% end %>
              </:col>
              <:col :let={booking} label="Lokasi"><%= booking.location %></:col>
              <:col :let={booking} label="Tarikh & Masa Guna">
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900">
                    <%= Calendar.strftime(booking.usage_at, "%d-%m-%Y") %>
                  </span>
                  <span class="text-sm text-gray-500">
                    <%= Calendar.strftime(booking.usage_at, "%H:%M") %>
                  </span>
                </div>
              </:col>
              <:col :let={booking} label="Tarikh & Masa Pulang">
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900">
                    <%= Calendar.strftime(booking.return_at, "%d-%m-%Y") %>
                  </span>
                  <span class="text-sm text-gray-500">
                    <%= Calendar.strftime(booking.return_at, "%H:%M") %>
                  </span>
                </div>
              </:col>
              <:col :let={booking} label="Kuantiti diminta"><%= booking.requested_quantity %> unit</:col>
              <:col :let={booking} label="Catatan"><%= booking.additional_notes %></:col>
              <:col :let={booking} label="Status">
                <span class={"px-2 py-1 rounded-full text-white " <>
                  case booking.status do
                    "pending" -> "bg-yellow-500"
                    "approved" -> "bg-green-500"
                    "rejected" -> "bg-red-500"
                    "completed" -> "bg-blue-500"
                    "cancelled" -> "bg-gray-400"
                    _ -> "bg-gray-400"
                  end}>
                  <%= Spato.Bookings.EquipmentBooking.human_status(booking.status) %>
                </span>
                <%= if booking.status in ["rejected", "cancelled"] do %>
                  <%= if booking.rejection_reason do %>
                    <p class="text-xs text-gray-500">Sebab: <%= booking.rejection_reason %></p>
                  <% end %>
                <% end %>
              </:col>
            </.table>
              <!-- Pagination -->
              <%= if @equipment_total_pages > 1 do %>
                <div class="relative flex items-center mt-4">
                  <div class="flex-1">
                    <button phx-click="paginate_history" phx-value-page={max(@equipment_page - 1, 1)} class={"px-3 py-1 border rounded " <>
                      if @equipment_page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Sebelumnya
                    </button>
                  </div>
                  <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
                    <%= for p <- 1..@equipment_total_pages do %>
                      <button phx-click="paginate_history" phx-value-page={p} class={"px-3 py-1 border rounded " <>
                        if p == @equipment_page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                        <%= p %>
                      </button>
                    <% end %>
                  </div>
                  <div class="flex-1 text-right">
                    <button phx-click="paginate_history" phx-value-page={min(@equipment_page + 1, @equipment_total_pages)} class={"px-3 py-1 border rounded " <>
                      if @equipment_page == @equipment_total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Seterusnya
                    </button>
                  </div>
                </div>
              <% end %>
            </section>
          <% end %>

          <!-- Meeting Room Table -->
          <%= if @selected_table == :meeting_room do %>
            <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
              <div class="flex flex-col mb-4 gap-2">
                <div class="flex items-center justify-between">
                  <h2 class="text-lg font-semibold text-gray-900">Sejarah Tempahan Bilik Mesyuarat</h2>
                </div>

                <div class="flex flex-wrap gap-2 mt-2">
                  <form phx-change="history_search" class="flex-1 min-w-[200px]">
                    <input type="text" name="q" value={@search_query} placeholder="Cari tujuan, nama bilik..." class="w-full border rounded-md px-2 py-1 text-sm"/>
                  </form>
                  <form phx-change="history_filter_status">
                    <select name="status" class="border rounded-md px-2 pr-8 py-1 text-sm">
                      <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                      <option value="rejected" selected={@filter_status == "rejected"}>Ditolak</option>
                      <option value="completed" selected={@filter_status == "completed"}>Selesai</option>
                      <option value="cancelled" selected={@filter_status == "cancelled"}>Dibatalkan</option>
                    </select>
                  </form>
                  <form phx-change="history_filter_date">
                    <input type="date" name="date" value={@filter_date} class="border rounded-md px-2 py-1 text-sm"/>
                  </form>
                </div>
              </div>

              <div class="mb-2 text-sm text-gray-600">
                <%= if @room_filtered_count == 0 do %>
                  Tiada tempahan ditemui
                <% else %>
                  <%= @room_filtered_count %> tempahan ditemui
                <% end %>
              </div>

              <.table id="room_history" rows={@room_history_page}>
              <:col :let={booking} label="ID"><%= booking.id %></:col>
              <:col :let={booking} label="Bilik Mesyuarat">
                <% room = booking.meeting_room || booking.room %>
                <%= if room do %>
                  <div class="flex flex-col">
                    <div class="font-semibold text-gray-900">
                      <%= room.name %>
                    </div>
                    <div class="text-sm text-gray-500">
                      <%= room.location %>
                    </div>
                    <div class="mt-1">
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">
                        Kapasiti: <%= room.capacity %>
                      </span>
                    </div>
                  </div>
                <% else %>
                  <span class="text-gray-400">—</span>
                <% end %>
              </:col>
              <:col :let={booking} label="Peserta">
                <div class="flex items-center gap-1">
                  <.icon name="hero-user" class="w-4 h-4 text-gray-500" />
                  <% room = booking.meeting_room || booking.room %>
                  <span><%= booking.participants %> / <%= room && room.capacity %></span>
                </div>
              </:col>
              <:col :let={booking} label="Tujuan">
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900"><%= booking.purpose %></span>
                </div>
              </:col>
              <:col :let={booking} label="Masa Mula">
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900">
                    <%= Calendar.strftime(booking.start_time, "%d-%m-%Y") %>
                  </span>
                  <span class="text-sm text-gray-500">
                    <%= Calendar.strftime(booking.start_time, "%H:%M") %>
                  </span>
                </div>
              </:col>
              <:col :let={booking} label="Masa Tamat">
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900">
                    <%= Calendar.strftime(booking.end_time, "%d-%m-%Y") %>
                  </span>
                  <span class="text-sm text-gray-500">
                    <%= Calendar.strftime(booking.end_time, "%H:%M") %>
                  </span>
                </div>
              </:col>
              <:col :let={booking} label="Catatan"><%= booking.notes %></:col>
              <:col :let={booking} label="Status">
                <span class={"px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
                  case booking.status do
                    "pending" -> "bg-yellow-500"
                    "approved" -> "bg-green-500"
                    "rejected" -> "bg-red-500"
                    "completed" -> "bg-blue-500"
                    "cancelled" -> "bg-gray-400"
                    _ -> "bg-gray-400"
                  end}>
                  <%= Spato.Bookings.MeetingRoomBooking.human_status(booking.status) %>
                </span>
              </:col>
            </.table>
              <%= if @room_total_pages > 1 do %>
                <div class="relative flex items-center mt-4">
                  <div class="flex-1">
                    <button phx-click="paginate_history" phx-value-page={max(@room_page - 1, 1)} class={"px-3 py-1 border rounded " <>
                      if @room_page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Sebelumnya
                    </button>
                  </div>
                  <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
                    <%= for p <- 1..@room_total_pages do %>
                      <button phx-click="paginate_history" phx-value-page={p} class={"px-3 py-1 border rounded " <>
                        if p == @room_page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                        <%= p %>
                      </button>
                    <% end %>
                  </div>
                  <div class="flex-1 text-right">
                    <button phx-click="paginate_history" phx-value-page={min(@room_page + 1, @room_total_pages)} class={"px-3 py-1 border rounded " <>
                      if @room_page == @room_total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Seterusnya
                    </button>
                  </div>
                </div>
              <% end %>
            </section>
          <% end %>

          <!-- Vehicle Table -->
          <%= if @selected_table == :vehicle do %>
            <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
              <div class="flex flex-col mb-4 gap-2">
                <div class="flex items-center justify-between">
                  <h2 class="text-lg font-semibold text-gray-900">Sejarah Tempahan Kenderaan</h2>
                </div>

                <div class="flex flex-wrap gap-2 mt-2">
                  <form phx-change="history_search" class="flex-1 min-w-[200px]">
                    <input type="text" name="q" value={@search_query} placeholder="Cari tujuan, destinasi..." class="w-full border rounded-md px-2 py-1 text-sm"/>
                  </form>
                  <form phx-change="history_filter_status">
                    <select name="status" class="border rounded-md px-2 pr-8 py-1 text-sm">
                      <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                      <option value="rejected" selected={@filter_status == "rejected"}>Ditolak</option>
                      <option value="completed" selected={@filter_status == "completed"}>Selesai</option>
                      <option value="cancelled" selected={@filter_status == "cancelled"}>Dibatalkan</option>
                    </select>
                  </form>
                  <form phx-change="history_filter_date">
                    <input type="date" name="date" value={@filter_date} class="border rounded-md px-2 py-1 text-sm"/>
                  </form>
                </div>
              </div>

              <div class="mb-2 text-sm text-gray-600">
                <%= if @vehicle_filtered_count == 0 do %>
                  Tiada tempahan ditemui
                <% else %>
                  <%= @vehicle_filtered_count %> tempahan ditemui
                <% end %>
              </div>

              <.table id="vehicle_history" rows={@vehicle_history_page}>
              <:col :let={booking} label="ID"><%= booking.id %></:col>
              <:col :let={booking} label="Kenderaan">
                <%= if booking.vehicle do %>
                  <div class="flex flex-col">
                    <div class="font-semibold text-gray-900">
                      <%= booking.vehicle.name %>
                    </div>
                    <div class="text-sm text-gray-500">
                      <%= booking.vehicle.plate_number %>
                    </div>
                    <div class="mt-1">
                      <%= case booking.vehicle.type do %>
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
                <% else %>
                  <span class="text-gray-400">—</span>
                <% end %>
              </:col>
              <:col :let={booking} label="Kapasiti">
                <%= if booking.vehicle do %>
                  <div class="flex items-center gap-1">
                    <.icon name="hero-user" class="w-4 h-4 text-gray-500" />
                    <span><%= booking.passengers_number %> / <%= booking.vehicle.capacity %></span>
                  </div>
                <% else %>
                  -
                <% end %>
              </:col>
              <:col :let={booking} label="Tujuan & Lokasi">
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900"><%= booking.purpose %></span>
                  <span class="text-sm text-gray-500"><%= booking.trip_destination %></span>
                </div>
              </:col>
              <:col :let={booking} label="Masa Pickup">
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900">
                    <%= Calendar.strftime(booking.pickup_time, "%d-%m-%Y") %>
                  </span>
                  <span class="text-sm text-gray-500">
                    <%= Calendar.strftime(booking.pickup_time, "%H:%M") %>
                  </span>
                </div>
              </:col>
              <:col :let={booking} label="Masa Pulang">
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900">
                    <%= Calendar.strftime(booking.return_time, "%d-%m-%Y") %>
                  </span>
                  <span class="text-sm text-gray-500">
                    <%= Calendar.strftime(booking.return_time, "%H:%M") %>
                  </span>
                </div>
              </:col>
              <:col :let={booking} label="Catatan"><%= booking.additional_notes %></:col>
              <:col :let={booking} label="Status">
                <span class={"px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
                  case booking.status do
                    "pending" -> "bg-yellow-500"
                    "approved" -> "bg-green-500"
                    "rejected" -> "bg-red-500"
                    "completed" -> "bg-blue-500"
                    "cancelled" -> "bg-gray-400"
                    _ -> "bg-gray-400"
                  end}>
                  <%= Spato.Bookings.VehicleBooking.human_status(booking.status) %>
                </span>
                <%= if booking.status in ["rejected", "cancelled"] do %>
                  <%= if booking.rejection_reason do %>
                    <p class="text-xs text-gray-500">Sebab: <%= booking.rejection_reason %></p>
                  <% end %>
                <% end %>
              </:col>
            </.table>
              <%= if @vehicle_total_pages > 1 do %>
                <div class="relative flex items-center mt-4">
                  <div class="flex-1">
                    <button phx-click="paginate_history" phx-value-page={max(@vehicle_page - 1, 1)} class={"px-3 py-1 border rounded " <>
                      if @vehicle_page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Sebelumnya
                    </button>
                  </div>
                  <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
                    <%= for p <- 1..@vehicle_total_pages do %>
                      <button phx-click="paginate_history" phx-value-page={p} class={"px-3 py-1 border rounded " <>
                        if p == @vehicle_page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                        <%= p %>
                      </button>
                    <% end %>
                  </div>
                  <div class="flex-1 text-right">
                    <button phx-click="paginate_history" phx-value-page={min(@vehicle_page + 1, @vehicle_total_pages)} class={"px-3 py-1 border rounded " <>
                      if @vehicle_page == @vehicle_total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Seterusnya
                    </button>
                  </div>
                </div>
              <% end %>
            </section>
          <% end %>

          <!-- Catering Table -->
          <%= if @selected_table == :catering do %>
            <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
              <div class="flex flex-col mb-4 gap-2">
                <div class="flex items-center justify-between">
                  <h2 class="text-lg font-semibold text-gray-900">Sejarah Tempahan Katering</h2>
                </div>

                <div class="flex flex-wrap gap-2 mt-2">
                  <form phx-change="history_search" class="flex-1 min-w-[200px]">
                    <input type="text" name="q" value={@search_query} placeholder="Cari lokasi, permintaan khusus..." class="w-full border rounded-md px-2 py-1 text-sm"/>
                  </form>
                  <form phx-change="history_filter_status">
                    <select name="status" class="border rounded-md px-2 pr-8 py-1 text-sm">
                      <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                      <option value="rejected" selected={@filter_status == "rejected"}>Ditolak</option>
                      <option value="completed" selected={@filter_status == "completed"}>Selesai</option>
                      <option value="cancelled" selected={@filter_status == "cancelled"}>Dibatalkan</option>
                    </select>
                  </form>
                  <form phx-change="history_filter_date">
                    <input type="date" name="date" value={@filter_date} class="border rounded-md px-2 py-1 text-sm"/>
                  </form>
                </div>
              </div>

              <div class="mb-2 text-sm text-gray-600">
                <%= if @catering_filtered_count == 0 do %>
                  Tiada tempahan ditemui
                <% else %>
                  <%= @catering_filtered_count %> tempahan ditemui
                <% end %>
              </div>

              <.table id="catering_history" rows={@catering_history_page}>
              <:col :let={booking} label="ID"><%= booking.id %></:col>
              <:col :let={booking} label="Menu">
                <%= if booking.menu do %>
                  <div class="flex flex-col">
                    <div class="font-semibold text-gray-900">
                      <%= booking.menu.name %>
                    </div>
                    <div class="text-sm text-gray-500">
                      <%= booking.menu.description %>
                    </div>
                    <div class="mt-1">
                      <%= case booking.menu.type do %>
                        <% "all" -> %>
                          <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Semua</span>
                        <% "sarapan" -> %>
                          <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Sarapan</span>
                        <% "makan_tengahari" -> %>
                          <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-indigo-500">Makan Tengahari</span>
                        <% "minum_petang" -> %>
                          <span class="px-1.5 py-0.5 rounded-full text-black text-xs font-semibold bg-yellow-400">Minum Petang</span>
                        <% "minum_malam" -> %>
                          <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-red-500">Minum Malam</span>
                        <% "makan_malam" -> %>
                          <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-green-500">Makan Malam</span>
                        <% "minum_pagi" -> %>
                          <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Minum Pagi</span>
                      <% end %>
                    </div>
                  </div>
                <% else %>
                  <span class="text-gray-400">—</span>
                <% end %>
              </:col>
              <:col :let={booking} label="Tarikh & Masa">
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900">
                    <%= Calendar.strftime(booking.date, "%d-%m-%Y") %>
                  </span>
                  <span class="text-sm text-gray-500">
                    <%= Calendar.strftime(booking.time, "%H:%M") %>
                  </span>
                </div>
              </:col>
              <:col :let={booking} label="Lokasi & Peserta">
                <div class="flex flex-col">
                  <span class="font-medium text-gray-900"><%= booking.location %></span>
                  <span class="text-sm text-gray-500"><%= booking.participants %> orang</span>
                </div>
              </:col>
              <:col :let={booking} label="Jumlah Kos">
                <div class="font-medium text-gray-900">
                  <%= if booking.total_cost do %>
                    <%= Spato.Bookings.format_money(booking.total_cost) %>
                  <% else %>
                    RM 0.00
                  <% end %>
                </div>
              </:col>
              <:col :let={booking} label="Permintaan Khusus"><%= booking.special_request %></:col>
              <:col :let={booking} label="Status">
                <span class={"px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
                  case booking.status do
                    "pending" -> "bg-yellow-500"
                    "approved" -> "bg-green-500"
                    "rejected" -> "bg-red-500"
                    "completed" -> "bg-blue-500"
                    "cancelled" -> "bg-gray-400"
                    _ -> "bg-gray-400"
                  end}>
                  <%= Spato.Bookings.CateringBooking.human_status(booking.status) %>
                </span>
              </:col>
            </.table>
              <%= if @catering_total_pages > 1 do %>
                <div class="relative flex items-center mt-4">
                  <div class="flex-1">
                    <button phx-click="paginate_history" phx-value-page={max(@catering_page - 1, 1)} class={"px-3 py-1 border rounded " <>
                      if @catering_page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Sebelumnya
                    </button>
                  </div>
                  <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
                    <%= for p <- 1..@catering_total_pages do %>
                      <button phx-click="paginate_history" phx-value-page={p} class={"px-3 py-1 border rounded " <>
                        if p == @catering_page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                        <%= p %>
                      </button>
                    <% end %>
                  </div>
                  <div class="flex-1 text-right">
                    <button phx-click="paginate_history" phx-value-page={min(@catering_page + 1, @catering_total_pages)} class={"px-3 py-1 border rounded " <>
                      if @catering_page == @catering_total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Seterusnya
                    </button>
                  </div>
                </div>
              <% end %>
            </section>
          <% end %>
        </main>
      </div>
    </div>
    """
  end
end

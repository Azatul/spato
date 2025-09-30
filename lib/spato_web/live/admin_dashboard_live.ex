defmodule SpatoWeb.AdminDashboardLive do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar
  import Ecto.Query, warn: false

  alias Spato.Bookings
  alias Spato.Bookings.{MeetingRoomBooking, VehicleBooking, CateringBooking}
  alias Spato.Repo
  alias Spato.Notifications

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role != "admin" do
      {:halt,
       socket
       |> put_flash(:error, "Access denied")
       |> redirect(to: "/dashboard")}
    else
      vehicle_stats = Spato.Bookings.get_booking_stats()
      catering_stats = Spato.Bookings.get_catering_booking_stats()
      equipment_stats = Spato.Bookings.get_equipment_booking_stats()
      meeting_room_stats = Spato.Bookings.get_meeting_room_booking_stats()

      socket =
        socket
        |> assign(:page_title, "Admin Dashboard")
        |> assign(:active_tab, "admin_dashboard")
        |> assign(:sidebar_open, true)
        |> assign(:vehicle_stats, vehicle_stats)
        |> assign(:catering_stats, catering_stats)
        |> assign(:equipment_stats, equipment_stats)
        |> assign(:meeting_room_stats, meeting_room_stats)
        |> assign(:booking_filter, "all")
        |> assign(:view_mode, "week")
        |> assign(:search_query, "")
        |> assign(:date_from, Date.utc_today())
        |> assign(:date_to, Date.add(Date.utc_today(), 7))
        |> assign(:search_triggered, false)
        |> assign(:show_notifications, false)
        |> load_notifications()

      {:ok, load_dashboard_data(socket)}
    end
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, Phoenix.Component.update(socket, :sidebar_open, &(!&1))}
  end

  def handle_event("toggle_notifications", _params, socket) do
    {:noreply, assign(socket, :show_notifications, !socket.assigns.show_notifications)}
  end

  def handle_event("read_notification", %{"id" => id}, socket) do
    case Notifications.get_notification(id) do
      %{status: "unread"} = notification ->
        {:ok, _} = Notifications.mark_as_read(notification)
        socket = load_notifications(socket)
        {:noreply, socket}
      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("filter_booking", %{"type" => type}, socket) do
    socket = assign(socket, :booking_filter, type)
    {:noreply, load_dashboard_data(socket)}
  end

  def handle_event("change_view", %{"mode" => mode}, socket) do
    socket = assign(socket, :view_mode, mode)
    {:noreply, load_dashboard_data(socket)}
  end

  def handle_event("search", %{"query" => query}, socket) do
    socket = assign(socket, :search_query, query)
    {:noreply, socket}
  end

  def handle_event("date_filter", %{"from" => from, "to" => to}, socket) do
    socket =
      socket
      |> assign(:date_from, Date.from_iso8601!(from))
      |> assign(:date_to, Date.from_iso8601!(to))
    {:noreply, socket}
  end

  def handle_event("search_bookings", _params, socket) do
    socket = assign(socket, :search_triggered, true)
    {:noreply, load_dashboard_data(socket)}
  end

  defp load_dashboard_data(socket) do
    date_from = socket.assigns.date_from
    date_to = socket.assigns.date_to
    search_query = socket.assigns.search_query
    booking_filter = socket.assigns.booking_filter
    view_mode = socket.assigns.view_mode
    search_triggered = socket.assigns.search_triggered

    # Get all bookings for admin view
    all_bookings = get_all_admin_bookings()

    # Get filtered bookings for calendar
    bookings = get_filtered_admin_bookings(all_bookings, date_from, date_to, search_query, booking_filter, search_triggered)

    # Get calendar data based on view mode
    calendar_data = build_calendar_data(bookings, date_from, date_to, view_mode)

    socket
    |> assign(:bookings, bookings)
    |> assign(:calendar_data, calendar_data)
  end

  defp get_all_admin_bookings do
    # Get all booking types for admin view
    meeting_room_bookings =
      from(mrb in MeetingRoomBooking)
      |> Repo.all()
      |> Enum.map(&Map.put(&1, :type, :meeting_room))

    vehicle_bookings =
      from(vb in VehicleBooking)
      |> Repo.all()
      |> Enum.map(&Map.put(&1, :type, :vehicle))

    catering_bookings =
      from(cb in CateringBooking)
      |> Repo.all()
      |> Enum.map(&Map.put(&1, :type, :catering))

    meeting_room_bookings ++ vehicle_bookings ++ catering_bookings
  end

  defp get_filtered_admin_bookings(all_bookings, date_from, date_to, search_query, booking_filter, search_triggered) do
    # Filter by date range
    date_filtered =
      all_bookings
      |> Enum.filter(fn booking ->
        booking_date = get_booking_date(booking)
        Date.compare(booking_date, date_from) != :lt and Date.compare(booking_date, date_to) != :gt
      end)

    # Filter by type
    type_filtered =
      if booking_filter == "all" do
        date_filtered
      else
        date_filtered
        |> Enum.filter(fn booking ->
          case booking_filter do
            "meeting_room" -> booking.type == :meeting_room
            "vehicle" -> booking.type == :vehicle
            "catering" -> booking.type == :catering
            "equipment" -> booking.type == :equipment
            _ -> true
          end
        end)
      end

    # Filter by search query - only if search was triggered
    if search_query == "" or not search_triggered do
      type_filtered
    else
      type_filtered
      |> Enum.filter(fn booking ->
        search_term = String.downcase(search_query)
        case booking.type do
          :meeting_room ->
            String.contains?(String.downcase(booking.purpose || ""), search_term)
          :vehicle ->
            String.contains?(String.downcase(booking.purpose || ""), search_term) or
            String.contains?(String.downcase(booking.trip_destination || ""), search_term)
          :catering ->
            String.contains?(String.downcase(booking.location || ""), search_term)
          _ -> false
        end
      end)
    end
  end

  defp get_booking_date(booking) do
    case booking.type do
      :meeting_room -> booking.start_time |> DateTime.to_date()
      :vehicle -> booking.pickup_time |> DateTime.to_date()
      :catering -> booking.date
    end
  end

  defp build_calendar_data(bookings, date_from, date_to, view_mode) do
    case view_mode do
      "day" -> build_day_view(bookings, date_from)
      "week" -> build_week_view(bookings, date_from)
      "month" -> build_month_view(bookings, date_from)
    end
  end

  defp build_day_view(bookings, date) do
    # Get bookings for specific day
    day_bookings =
      bookings
      |> Enum.filter(fn booking ->
        booking_date = get_booking_date(booking)
        Date.compare(booking_date, date) == :eq
      end)

    # Group by time slots
    day_bookings
    |> Enum.group_by(&get_time_slot/1)
    |> Enum.map(fn {time_slot, booking_list} ->
      %{
        date: date,
        time_slot: time_slot,
        bookings: booking_list
      }
    end)
    |> Enum.sort_by(fn %{time_slot: time_slot} -> time_slot end)
  end

  defp build_week_view(bookings, start_date) do
    # Get week range
    week_start = Date.beginning_of_week(start_date)
    week_end = Date.end_of_week(start_date)

    # Generate all days in week
    week_days = Date.range(week_start, week_end) |> Enum.to_list()

    # Get bookings for the week
    week_bookings =
      bookings
      |> Enum.filter(fn booking ->
        booking_date = get_booking_date(booking)
        Date.compare(booking_date, week_start) != :lt and Date.compare(booking_date, week_end) != :gt
      end)

    # Group by date and time slot
    week_bookings
    |> Enum.group_by(fn booking ->
      booking_date = get_booking_date(booking)
      {booking_date, get_time_slot(booking)}
    end)
    |> Enum.map(fn {{date, time_slot}, booking_list} ->
      %{
        date: date,
        time_slot: time_slot,
        bookings: booking_list
      }
    end)
    |> Enum.sort_by(fn %{date: date, time_slot: time_slot} -> {date, time_slot} end)
  end

  defp build_month_view(bookings, start_date) do
    # Get month range
    month_start = Date.beginning_of_month(start_date)
    month_end = Date.end_of_month(start_date)

    # Get bookings for the month
    month_bookings =
      bookings
      |> Enum.filter(fn booking ->
        booking_date = get_booking_date(booking)
        Date.compare(booking_date, month_start) != :lt and Date.compare(booking_date, month_end) != :gt
      end)

    # Group by date and time slot
    month_bookings
    |> Enum.group_by(fn booking ->
      booking_date = get_booking_date(booking)
      {booking_date, get_time_slot(booking)}
    end)
    |> Enum.map(fn {{date, time_slot}, booking_list} ->
      %{
        date: date,
        time_slot: time_slot,
        bookings: booking_list
      }
    end)
    |> Enum.sort_by(fn %{date: date, time_slot: time_slot} -> {date, time_slot} end)
  end

  defp get_time_slot(booking) do
    case booking.type do
      :meeting_room ->
        start_time = booking.start_time
        hour = start_time.hour
        cond do
          hour >= 8 and hour < 9 -> "08:00-09:00"
          hour >= 9 and hour < 10 -> "09:00-10:00"
          hour >= 10 and hour < 11 -> "10:00-11:00"
          hour >= 11 and hour < 12 -> "11:00-12:00"
          hour >= 12 and hour < 13 -> "12:00-13:00"
          hour >= 13 and hour < 14 -> "13:00-14:00"
          hour >= 14 and hour < 15 -> "14:00-15:00"
          hour >= 15 and hour < 16 -> "15:00-16:00"
          hour >= 16 and hour < 17 -> "16:00-17:00"
          true -> "Lain-lain"
        end
      :vehicle ->
        pickup_time = booking.pickup_time
        hour = pickup_time.hour
        cond do
          hour >= 8 and hour < 9 -> "08:00-09:00"
          hour >= 9 and hour < 10 -> "09:00-10:00"
          hour >= 10 and hour < 11 -> "10:00-11:00"
          hour >= 11 and hour < 12 -> "11:00-12:00"
          hour >= 12 and hour < 13 -> "12:00-13:00"
          hour >= 13 and hour < 14 -> "13:00-14:00"
          hour >= 14 and hour < 15 -> "14:00-15:00"
          hour >= 15 and hour < 16 -> "15:00-16:00"
          hour >= 16 and hour < 17 -> "16:00-17:00"
          true -> "Lain-lain"
        end
      :catering ->
        time = booking.time
        hour = time.hour
        cond do
          hour >= 8 and hour < 9 -> "08:00-09:00"
          hour >= 9 and hour < 10 -> "09:00-10:00"
          hour >= 10 and hour < 11 -> "10:00-11:00"
          hour >= 11 and hour < 12 -> "11:00-12:00"
          hour >= 12 and hour < 13 -> "12:00-13:00"
          hour >= 13 and hour < 14 -> "13:00-14:00"
          hour >= 14 and hour < 15 -> "14:00-15:00"
          hour >= 15 and hour < 16 -> "15:00-16:00"
          hour >= 16 and hour < 17 -> "16:00-17:00"
          true -> "Lain-lain"
        end
    end
  end

  defp get_booking_color(type) do
    case type do
      :meeting_room -> "bg-gradient-to-r from-purple-100 to-purple-200 text-purple-800"
      :vehicle -> "bg-gradient-to-r from-teal-100 to-teal-200 text-teal-800"
      :catering -> "bg-gradient-to-r from-rose-100 to-rose-200 text-rose-800"
      :equipment -> "bg-gradient-to-r from-indigo-100 to-indigo-200 text-indigo-800"
    end
  end

  defp get_booking_title(booking) do
    case booking.type do
      :meeting_room -> "Bilik"
      :vehicle -> "Kenderaan"
      :catering -> "Katering"
      :equipment -> "Peralatan"
    end
  end

  defp load_notifications(socket) do
    admin_id = socket.assigns.current_user.id
    notifications = Notifications.list_admin_notifications(admin_id)
    unread_count = Notifications.count_unread(admin_id, :admin)

    socket
    |> assign(:notifications, notifications)
    |> assign(:unread_count, unread_count)
  end

  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
      <.headbar
        current_user={@current_user}
        open={@sidebar_open}
        toggle_event="toggle_sidebar"
        title={@page_title}
        notifications={@notifications}
        unread_count={@unread_count}
        show_notifications={@show_notifications}
      />

      <main class="flex-1 overflow-y-auto pt-20 p-6 transition-all duration-300 bg-gray-100">
      <body class="p-4 md:p-8">
        <!-- Top Section: Today's Reservations -->
        <section class="mb-8">
            <h2 class="text-xl md:text-2xl font-bold mb-4">Tempahan Menunggu Kelulusan</h2>
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">

                <!-- Card: Bilik mesyuarat (Meeting Room) -->
                <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                    <div>
                        <p class="text-sm text-gray-500">Bilik mesyuarat</p>
                        <p class="text-3xl font-bold mt-1 text-yellow-500"><%= @meeting_room_stats.pending %></p>
                    </div>
                    <div class="w-full flex justify-end">
                        <.link
                        navigate={"/admin/meeting_room_bookings?page=1&q=&status=pending&date="}
                        class="mt-4 inline-flex items-center justify-center px-3 py-1 bg-gradient-to-r from-yellow-400 to-yellow-500 text-black font-semibold rounded-lg shadow-md hover:from-yellow-500 hover:to-yellow-600 transition-all text-sm"
                        >
                        Ambil tindakan →
                        </.link>
                    </div>
                </div>

                <!-- Card: Kenderaan (Vehicle) -->
                <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                    <div>
                        <p class="text-sm text-gray-500">Kenderaan</p>
                        <p class="text-3xl font-bold mt-1 text-yellow-500"><%= @vehicle_stats.pending %></p>
                    </div>
                    <div class="w-full flex justify-end">
                        <.link
                        navigate={"/admin/vehicle_bookings?page=1&q=&status=pending&date="}
                        class="mt-4 inline-flex items-center justify-center px-3 py-1 bg-gradient-to-r from-yellow-400 to-yellow-500 text-black font-semibold rounded-lg shadow-md hover:from-yellow-500 hover:to-yellow-600 transition-all text-sm"
                        >
                            Ambil tindakan →
                        </.link>
                    </div>
                </div>

                <!-- Card: Katering (Catering) -->
                <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                    <div>
                        <p class="text-sm text-gray-500">Katering</p>
                        <p class="text-3xl font-bold mt-1 text-yellow-500"><%= @catering_stats.pending %></p>
                    </div>
                    <div class="w-full flex justify-end">
                    <.link
                    navigate={"/admin/catering_bookings?page=1&q=&status=pending&date="}
                    class="mt-4 inline-flex items-center justify-center px-3 py-1 bg-gradient-to-r from-yellow-400 to-yellow-500 text-black font-semibold rounded-lg shadow-md hover:from-yellow-500 hover:to-yellow-600 transition-all text-sm"
                    >
                    Ambil tindakan →
                    </.link>
                    </div>
                </div>

               <!-- Card: Peralatan (Equipment) -->
                <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                <div>
                    <p class="text-sm text-gray-500">Peralatan</p>
                    <p class="text-3xl font-bold mt-1 text-yellow-500"><%= @equipment_stats.pending %></p>
                </div>
                <div class="w-full flex justify-end">
                        <.link
                        navigate={"/admin/equipment_bookings?page=1&q=&status=pending&date="}
                        class="mt-4 inline-flex items-center justify-center px-3 py-1 bg-gradient-to-r from-yellow-400 to-yellow-500 text-black font-semibold rounded-lg shadow-md hover:from-yellow-500 hover:to-yellow-600 transition-all text-sm"
                        >
                        Ambil tindakan →
                        </.link>
                </div>
                </div>
            </div>
        </section>

        <!-- Search and Filter Section -->
        <div class="bg-white p-6 rounded-xl shadow-lg mb-6 animate-slide-in-up">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-xl font-bold text-gray-800">Carian & Penapis</h3>
            <i class="fa-solid fa-search text-gray-400"></i>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-5 gap-4">
            <!-- Search Bar -->
            <div class="relative">
              <input
                type="text"
                placeholder="Cari tempahan..."
                value={@search_query}
                phx-change="search"
                phx-value-query={@search_query}
                class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-300 focus:border-transparent transition-all duration-300"
              />
              <i class="fa-solid fa-search absolute left-3 top-3 text-gray-400"></i>
            </div>

            <!-- Filter Dropdown -->
            <select
              phx-change="filter_booking"
              phx-value-type={@booking_filter}
              class="border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-blue-300 focus:border-transparent transition-all duration-300">
              <option value="all">Semua Tempahan</option>
              <option value="meeting_room">Bilik Mesyuarat</option>
              <option value="vehicle">Kenderaan</option>
              <option value="catering">Katering</option>
              <option value="equipment">Peralatan</option>
            </select>

            <!-- Date From -->
            <div class="relative">
              <label class="absolute -top-2 left-2 bg-white px-1 text-xs text-gray-600">Dari</label>
              <input
                type="date"
                value={@date_from}
                phx-change="date_filter"
                phx-value-from={@date_from}
                phx-value-to={@date_to}
                class="w-full border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-blue-300 focus:border-transparent transition-all duration-300"
              />
            </div>

            <!-- Date To -->
            <div class="relative">
              <label class="absolute -top-2 left-2 bg-white px-1 text-xs text-gray-600">Hingga</label>
              <input
                type="date"
                value={@date_to}
                phx-change="date_filter"
                phx-value-from={@date_from}
                phx-value-to={@date_to}
                class="w-full border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-blue-300 focus:border-transparent transition-all duration-300"
              />
            </div>

            <!-- Search Button -->
            <button
              phx-click="search_bookings"
              class="flex items-center justify-center px-6 py-2 bg-gradient-to-r from-blue-500 to-blue-600 text-white rounded-lg shadow-md hover:from-blue-600 hover:to-blue-700 transition-all duration-300 transform hover:scale-105">
              <i class="fa-solid fa-search mr-2"></i>
              Cari
            </button>
          </div>
        </div>

        <!-- Calendar Table -->
        <div class="bg-white p-6 rounded-xl shadow-lg min-h-[400px] animate-slide-in-up">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h3 class="text-xl font-bold text-gray-800">Kalendar Tempahan Admin</h3>
              <p class="text-gray-500">Semua tempahan sistem</p>
            </div>
            <div class="flex items-center space-x-2">
              <span class="text-gray-600 text-sm">Paparan:</span>
              <div class="flex space-x-1 bg-gray-100 rounded-lg p-1">
                <button
                  phx-click="change_view"
                  phx-value-mode="day"
                  class={"px-3 py-1 rounded-md text-sm transition-colors " <> if(@view_mode == "day", do: "bg-blue-300 text-blue-800", else: "text-gray-600 hover:bg-gray-200")}>
                  Hari
                </button>
                <button
                  phx-click="change_view"
                  phx-value-mode="week"
                  class={"px-3 py-1 rounded-md text-sm transition-colors " <> if(@view_mode == "week", do: "bg-blue-300 text-blue-800", else: "text-gray-600 hover:bg-gray-200")}>
                  Minggu
                </button>
                <button
                  phx-click="change_view"
                  phx-value-mode="month"
                  class={"px-3 py-1 rounded-md text-sm transition-colors " <> if(@view_mode == "month", do: "bg-blue-300 text-blue-800", else: "text-gray-600 hover:bg-gray-200")}>
                  Bulan
                </button>
              </div>
            </div>
          </div>

          <div class="overflow-x-auto">
            <table class="min-w-full bg-white border border-gray-200 rounded-lg">
              <thead>
                <tr class="bg-gradient-to-r from-blue-50 to-blue-100">
                  <th class="px-4 py-3 border-r border-gray-200 text-left text-sm font-semibold text-gray-700 w-48">
                    Tempahan <%= String.capitalize(@view_mode) %> Ini
                  </th>
                  <th class="px-4 py-3 border-r border-gray-200 text-sm font-semibold text-gray-700 w-32">08:00-09:00</th>
                  <th class="px-4 py-3 border-r border-gray-200 text-sm font-semibold text-gray-700 w-32">09:00-10:00</th>
                  <th class="px-4 py-3 border-r border-gray-200 text-sm font-semibold text-gray-700 w-32">10:00-11:00</th>
                  <th class="px-4 py-3 border-r border-gray-200 text-sm font-semibold text-gray-700 w-32">11:00-12:00</th>
                  <th class="px-4 py-3 border-r border-gray-200 text-sm font-semibold text-gray-700 w-32">12:00-13:00</th>
                  <th class="px-4 py-3 border-r border-gray-200 text-sm font-semibold text-gray-700 w-32">13:00-14:00</th>
                  <th class="px-4 py-3 border-r border-gray-200 text-sm font-semibold text-gray-700 w-32">14:00-15:00</th>
                  <th class="px-4 py-3 border-r border-gray-200 text-sm font-semibold text-gray-700 w-32">15:00-16:00</th>
                  <th class="px-4 py-3 text-sm font-semibold text-gray-700 w-32">16:00-17:00</th>
                </tr>
              </thead>
              <tbody>
                <%= for calendar_item <- @calendar_data do %>
                  <tr class="hover:bg-gray-50 transition-colors">
                    <td class="px-4 py-3 border-r border-gray-200 border-t text-sm text-gray-600 font-medium">
                      <%= Calendar.strftime(calendar_item.date, "%d/%m/%Y") %>
                    </td>
                    <%= for time_slot <- ["08:00-09:00", "09:00-10:00", "10:00-11:00", "11:00-12:00", "12:00-13:00", "13:00-14:00", "14:00-15:00", "15:00-16:00", "16:00-17:00"] do %>
                      <td class="px-4 py-3 border-r border-t">
                        <%= if calendar_item.time_slot == time_slot do %>
                          <%= for booking <- calendar_item.bookings do %>
                            <div class={"h-8 rounded-md flex items-center justify-center text-xs font-medium " <> get_booking_color(booking.type)}>
                              <span><%= get_booking_title(booking) %></span>
                            </div>
                          <% end %>
                        <% end %>
                      </td>
                    <% end %>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>

          <!-- Empty State -->
          <%= if Enum.empty?(@calendar_data) do %>
            <div class="text-center py-8 text-gray-500 animate-fade-in">
              <i class="fa-solid fa-calendar-times text-4xl mb-3"></i>
              <p>Tiada tempahan dijumpai untuk tarikh yang dipilih</p>
            </div>
          <% end %>
        </div>

    </body>
      </main>
    </div>

    <style>
      @keyframes fadeIn {
        from { opacity: 0; transform: translateY(20px); }
        to { opacity: 1; transform: translateY(0); }
      }

      @keyframes slideInLeft {
        from { opacity: 0; transform: translateX(-50px); }
        to { opacity: 1; transform: translateX(0); }
      }

      @keyframes slideInRight {
        from { opacity: 0; transform: translateX(50px); }
        to { opacity: 1; transform: translateX(0); }
      }

      @keyframes slideInUp {
        from { opacity: 0; transform: translateY(30px); }
        to { opacity: 1; transform: translateY(0); }
      }

      @keyframes countUp {
        from { opacity: 0; transform: scale(0.5); }
        to { opacity: 1; transform: scale(1); }
      }

      .animate-fade-in { animation: fadeIn 0.6s ease-out; }
      .animate-slide-in-left { animation: slideInLeft 0.6s ease-out; }
      .animate-slide-in-right { animation: slideInRight 0.6s ease-out; }
      .animate-slide-in-up { animation: slideInUp 0.6s ease-out; }
      .animate-count-up { animation: countUp 0.8s ease-out; }
    </style>
    """
  end
end

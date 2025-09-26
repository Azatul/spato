defmodule SpatoWeb.UserDashboardLive do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar
  import Ecto.Query, warn: false

  alias Spato.Bookings
  alias Spato.Bookings.{MeetingRoomBooking, VehicleBooking, CateringBooking}
  alias Spato.Repo

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "User Dashboard")
      |> assign(:active_tab, "dashboard")
      |> assign(:sidebar_open, true)
      |> assign(:booking_filter, "all")
      |> assign(:view_mode, "day")
      |> assign(:search_query, "")
      |> assign(:date_from, Date.utc_today())
      |> assign(:date_to, Date.add(Date.utc_today(), 7))
      |> assign(:search_triggered, false)

    {:ok, load_dashboard_data(socket)}
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, Phoenix.Component.update(socket, :sidebar_open, &(!&1))}
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

  def handle_event("book_room", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/meeting-rooms")}
  end

  def handle_event("book_vehicle", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/vehicles")}
  end

  def handle_event("book_catering", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/catering-menus")}
  end

  def handle_event("book_equipment", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/equipments")}
  end

  defp load_dashboard_data(socket) do
    user = socket.assigns.current_user
    date_from = socket.assigns.date_from
    date_to = socket.assigns.date_to
    search_query = socket.assigns.search_query
    booking_filter = socket.assigns.booking_filter
    view_mode = socket.assigns.view_mode
    search_triggered = socket.assigns.search_triggered

    # Get statistics
    stats = get_user_booking_stats(user, date_from, date_to)

    # Get filtered bookings for calendar
    bookings = get_filtered_bookings(user, date_from, date_to, search_query, booking_filter, search_triggered)

    # Get calendar data based on view mode
    calendar_data = build_calendar_data(bookings, date_from, date_to, view_mode)

    socket
    |> assign(:stats, stats)
    |> assign(:bookings, bookings)
    |> assign(:calendar_data, calendar_data)
  end

  defp get_user_booking_stats(user, date_from, date_to) do
    # This week's bookings
    week_start = Date.beginning_of_week(date_from)
    week_end = Date.end_of_week(date_from)

    # This month's bookings
    month_start = Date.beginning_of_month(date_from)
    month_end = Date.end_of_month(date_from)

    # All user bookings
    all_bookings = get_all_user_bookings(user)

    # This week's bookings
    week_bookings =
      all_bookings
      |> Enum.filter(fn booking ->
        booking_date = get_booking_date(booking)
        Date.compare(booking_date, week_start) != :lt and Date.compare(booking_date, week_end) != :gt
      end)

    # Pending bookings
    pending_bookings =
      all_bookings
      |> Enum.filter(fn booking -> get_booking_status(booking) == "pending" end)

    # This month's completed bookings
    month_completed =
      all_bookings
      |> Enum.filter(fn booking ->
        booking_date = get_booking_date(booking)
        status = get_booking_status(booking)
        Date.compare(booking_date, month_start) != :lt and
        Date.compare(booking_date, month_end) != :gt and
        status == "completed"
      end)

    %{
      week_activity: length(week_bookings),
      pending_approvals: length(pending_bookings),
      month_completed: length(month_completed)
    }
  end

  defp get_all_user_bookings(user) do
    # Get all booking types for the user
    meeting_room_bookings =
      from(mrb in MeetingRoomBooking, where: mrb.user_id == ^user.id)
      |> Repo.all()
      |> Enum.map(&Map.put(&1, :type, :meeting_room))

    vehicle_bookings =
      from(vb in VehicleBooking, where: vb.user_id == ^user.id)
      |> Repo.all()
      |> Enum.map(&Map.put(&1, :type, :vehicle))

    catering_bookings =
      from(cb in CateringBooking, where: cb.user_id == ^user.id)
      |> Repo.all()
      |> Enum.map(&Map.put(&1, :type, :catering))

    meeting_room_bookings ++ vehicle_bookings ++ catering_bookings
  end

  defp get_booking_date(booking) do
    case booking.type do
      :meeting_room -> booking.start_time |> DateTime.to_date()
      :vehicle -> booking.pickup_time |> DateTime.to_date()
      :catering -> booking.date
    end
  end

  defp get_booking_status(booking) do
    booking.status
  end

  defp get_filtered_bookings(user, date_from, date_to, search_query, booking_filter, search_triggered) do
    all_bookings = get_all_user_bookings(user)

    # Filter by status FIRST - only show approved bookings
    approved_bookings =
      all_bookings
      |> Enum.filter(fn booking ->
        get_booking_status(booking) == "approved"
      end)

    # Filter by date range
    date_filtered =
      approved_bookings
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

  def render(assigns) do
    ~H"""
    <div class="flex w-screen h-screen bg-gray-200 font-sans overflow-hidden">
      <!-- Sidebar -->
      <.sidebar
          active_tab={@active_tab}
          current_user={@current_user}
          open={@sidebar_open}
          toggle_event="toggle_sidebar"
        />

      <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

      <!-- Main Content -->
      <main class="flex-1 pt-20 p-8 overflow-y-auto bg-gray-100">

        <!-- Welcome -->
        <div class="mb-8 animate-fade-in">
          <h1 class="text-3xl font-bold text-black">Selamat Kembali, <%= if @current_user.user_profile do %><%= @current_user.user_profile.full_name %><% else %><%= @current_user.email %><% end %>!</h1>
          <p class="text-gray-500 mt-1">
            Berikut ialah ikhtisar ringkas tempahan dan aktiviti anda
          </p>
        </div>

        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <!-- Aktiviti Tempahan -->
          <div class="bg-white p-6 rounded-xl shadow-md flex justify-between items-center min-h-[130px] border-l-4 border-purple-300 transition-transform hover:scale-105">
            <div>
              <h3 class="text-gray-600 text-sm font-semibold">Aktiviti Tempahan</h3>
              <p class="text-4xl font-bold text-gray-800 mt-2"><%= @stats.week_activity %></p>
              <p class="text-gray-500 text-sm mt-1">Minggu Ini</p>
            </div>
            <div class="bg-purple-100 p-3 rounded-full">
              <i class="fa-solid fa-calendar-days text-purple-500 text-2xl"></i>
            </div>
          </div>

          <!-- Menunggu Kelulusan -->
          <div class="bg-white p-6 rounded-xl shadow-md flex justify-between items-center min-h-[130px] border-l-4 border-amber-300 transition-transform hover:scale-105">
            <div>
              <h3 class="text-gray-600 text-sm font-semibold">Menunggu Kelulusan</h3>
              <p class="text-4xl font-bold text-gray-800 mt-2"><%= @stats.pending_approvals %></p>
              <p class="text-gray-500 text-sm mt-1">Menunggu Jawapan</p>
            </div>
            <div class="bg-amber-100 p-3 rounded-full">
              <i class="fa-solid fa-clock text-amber-500 text-2xl"></i>
            </div>
          </div>

          <!-- Jumlah Bulan Ini -->
          <div class="bg-white p-6 rounded-xl shadow-md flex justify-between items-center min-h-[130px] border-l-4 border-teal-300 transition-transform hover:scale-105">
            <div>
              <h3 class="text-gray-600 text-sm font-semibold">Jumlah Bulan Ini</h3>
              <p class="text-4xl font-bold text-gray-800 mt-2"><%= @stats.month_completed %></p>
              <p class="text-gray-500 text-sm mt-1">Tempahan Selesai</p>
            </div>
            <div class="bg-teal-100 p-3 rounded-full">
              <i class="fa-solid fa-check-circle text-teal-500 text-2xl"></i>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex justify-center flex-wrap gap-4 mb-8">
          <button
            phx-click="book_room"
            class="flex items-center px-6 py-3 bg-gradient-to-r from-purple-200 to-purple-300 text-purple-800 rounded-xl shadow-md hover:from-purple-300 hover:to-purple-400 transition-all duration-300 transform hover:scale-105 animate-fade-in">
            <i class="fa-solid fa-users mr-2"></i> Tempah Bilik Mesyuarat
          </button>
          <button
            phx-click="book_vehicle"
            class="flex items-center px-6 py-3 bg-gradient-to-r from-orange-200 to-orange-300 text-orange-800 rounded-xl shadow-md hover:from-orange-300 hover:to-orange-400 transition-all duration-300 transform hover:scale-105 animate-fade-in">
            <i class="fa-solid fa-car mr-2"></i> Tempah Kenderaan
          </button>
          <button
            phx-click="book_catering"
            class="flex items-center px-6 py-3 bg-gradient-to-r from-rose-200 to-rose-300 text-rose-800 rounded-xl shadow-md hover:from-rose-300 hover:to-rose-400 transition-all duration-300 transform hover:scale-105 animate-fade-in">
            <i class="fa-solid fa-utensils mr-2"></i> Tempah Katering
          </button>
          <button
            phx-click="book_equipment"
            class="flex items-center px-6 py-3 bg-gradient-to-r from-indigo-200 to-indigo-300 text-indigo-800 rounded-xl shadow-md hover:from-indigo-300 hover:to-indigo-400 transition-all duration-300 transform hover:scale-105 animate-fade-in">
            <i class="fa-solid fa-tools mr-2"></i> Tempah Peralatan
          </button>
        </div>

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
                class="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-300 focus:border-transparent transition-all duration-300"
              />
              <i class="fa-solid fa-search absolute left-3 top-3 text-gray-400"></i>
            </div>

            <!-- Filter Dropdown -->
            <select
              phx-change="filter_booking"
              phx-value-type={@booking_filter}
              class="border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-purple-300 focus:border-transparent transition-all duration-300">
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
                class="w-full border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-purple-300 focus:border-transparent transition-all duration-300"
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
                class="w-full border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-purple-300 focus:border-transparent transition-all duration-300"
              />
            </div>

            <!-- Search Button -->
            <button
              phx-click="search_bookings"
              class="flex items-center justify-center px-6 py-2 bg-gradient-to-r from-purple-500 to-purple-600 text-white rounded-lg shadow-md hover:from-purple-600 hover:to-purple-700 transition-all duration-300 transform hover:scale-105">
              <i class="fa-solid fa-search mr-2"></i>
              Cari
            </button>
          </div>
        </div>

        <!-- Calendar Table -->
        <div class="bg-white p-6 rounded-xl shadow-lg min-h-[400px] animate-slide-in-up">
          <div class="flex items-center justify-between mb-6">
            <div>
              <h3 class="text-xl font-bold text-gray-800">Kalendar Tempahan Saya</h3>
              <p class="text-gray-500">Tempahan yang diluluskan</p>
            </div>
            <div class="flex items-center space-x-2">
              <span class="text-gray-600 text-sm">Paparan:</span>
              <div class="flex space-x-1 bg-gray-100 rounded-lg p-1">
                <button
                  phx-click="change_view"
                  phx-value-mode="day"
                  class={"px-3 py-1 rounded-md text-sm transition-colors " <> if(@view_mode == "day", do: "bg-purple-300 text-purple-800", else: "text-gray-600 hover:bg-gray-200")}>
                  Hari
                </button>
                <button
                  phx-click="change_view"
                  phx-value-mode="week"
                  class={"px-3 py-1 rounded-md text-sm transition-colors " <> if(@view_mode == "week", do: "bg-purple-300 text-purple-800", else: "text-gray-600 hover:bg-gray-200")}>
                  Minggu
                </button>
                <button
                  phx-click="change_view"
                  phx-value-mode="month"
                  class={"px-3 py-1 rounded-md text-sm transition-colors " <> if(@view_mode == "month", do: "bg-purple-300 text-purple-800", else: "text-gray-600 hover:bg-gray-200")}>
                  Bulan
                </button>
              </div>
            </div>
          </div>

          <div class="overflow-x-auto">
            <table class="min-w-full bg-white border border-gray-200 rounded-lg">
              <thead>
                <tr class="bg-gradient-to-r from-purple-50 to-purple-100">
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
end

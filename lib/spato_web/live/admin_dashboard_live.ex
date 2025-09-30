defmodule SpatoWeb.AdminDashboardLive do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar
  alias Spato.Notifications
  alias Spato.Bookings

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  def mount(_params, _session, socket) do
    if socket.assigns.current_user.role != "admin" do
      {:halt,
       socket
       |> put_flash(:error, "Access denied")
       |> redirect(to: "/dashboard")}
    else
      vehicle_stats = Bookings.get_booking_stats()
      catering_stats = Bookings.get_catering_booking_stats()
      equipment_stats = Bookings.get_equipment_booking_stats()
      meeting_room_stats = Bookings.get_meeting_room_booking_stats()

      socket =
        socket
        |> assign(:page_title, "Admin Dashboard")
        |> assign(:active_tab, "admin_dashboard")
        |> assign(:sidebar_open, true)
        |> assign(:vehicle_stats, vehicle_stats)
        |> assign(:catering_stats, catering_stats)
        |> assign(:equipment_stats, equipment_stats)
        |> assign(:meeting_room_stats, meeting_room_stats)
        |> assign_calendar_defaults()

      socket = load_calendar(socket)

      {:ok, socket}
    end
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
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

  def handle_event("set_view", %{"view" => view}, socket) do
    socket = socket |> assign(:view, view) |> adjust_range_for_view()
    {:noreply, load_calendar(socket)}
  end

  def handle_event("nav", %{"dir" => dir}, socket) do
    socket =
      case {socket.assigns.view, dir} do
        {"day", "prev"} -> shift_range(socket, -1)
        {"day", "next"} -> shift_range(socket, 1)
        {"week", "prev"} -> shift_range(socket, -7)
        {"week", "next"} -> shift_range(socket, 7)
        {"month", "prev"} -> shift_month(socket, -1)
        {"month", "next"} -> shift_month(socket, 1)
        _ -> socket
      end

    {:noreply, load_calendar(socket)}
  end

  def handle_event("set_range", %{"from" => from, "to" => to}, socket) do
    socket =
      case {Date.from_iso8601(from), Date.from_iso8601(to)} do
        {{:ok, from_d}, {:ok, to_d}} ->
          socket
          |> assign(:date_from, from_d)
          |> assign(:date_to, to_d)
        _ -> socket
      end

    {:noreply, load_calendar(socket)}
  end

  def handle_event("filter_type", %{"type" => type}, socket) do
    socket = assign(socket, :filter_type, type)
    {:noreply, load_calendar(socket)}
  end

  defp load_notifications(socket) do
    admin_id = socket.assigns.current_user.id
    notifications = Notifications.list_admin_notifications(admin_id)
    unread_count = Notifications.count_unread(admin_id, :admin)

    socket
    |> assign(:notifications, notifications)
    |> assign(:unread_count, unread_count)
  end

  defp assign_calendar_defaults(socket) do
    today = Date.utc_today()
    weekday = Date.day_of_week(today)
    week_start = Date.add(today, -weekday + 1)
    week_end = Date.add(week_start, 6)

    socket
    |> assign(:view, "week")
    |> assign(:date_from, week_start)
    |> assign(:date_to, week_end)
    |> assign(:filter_type, "all")
    |> assign(:events, [])
    |> assign(:events_by_day, %{})
    |> assign(:calendar_days, Enum.to_list(Date.range(week_start, week_end)))
  end

  defp start_of_day(%Date{} = d) do
    {:ok, dt} = DateTime.new(d, ~T[00:00:00], "Etc/UTC")
    dt
  end

  defp end_of_day(%Date{} = d) do
    {:ok, dt} = DateTime.new(d, ~T[23:59:59], "Etc/UTC")
    dt
  end

  defp load_calendar(socket) do
    from_dt = start_of_day(socket.assigns.date_from)
    to_dt = end_of_day(socket.assigns.date_to)
    events = Bookings.list_approved_bookings_in_range(from_dt, to_dt)
    events =
      case socket.assigns.filter_type do
        "all" -> events
        type -> Enum.filter(events, &(&1.type == type))
      end
    events_by_day = group_events_by_day(events)
    days = Enum.to_list(Date.range(socket.assigns.date_from, socket.assigns.date_to))

    socket
    |> assign(:events, events)
    |> assign(:events_by_day, events_by_day)
    |> assign(:calendar_days, days)
  end

  defp group_events_by_day(events) do
    Enum.reduce(events, %{}, fn ev, acc ->
      date = ev.usage_at |> DateTime.to_date()
      Map.update(acc, date, [ev], fn list -> [ev | list] end)
    end)
    |> Enum.into(%{}, fn {k, v} -> {k, Enum.sort_by(v, & &1.usage_at)} end)
  end

  defp adjust_range_for_view(socket) do
    case socket.assigns.view do
      "day" ->
        today = socket.assigns.date_from
        socket |> assign(:date_from, today) |> assign(:date_to, today)
      "week" ->
        today = Date.utc_today()
        weekday = Date.day_of_week(today)
        week_start = Date.add(today, -weekday + 1)
        week_end = Date.add(week_start, 6)
        socket |> assign(:date_from, week_start) |> assign(:date_to, week_end)
      "month" ->
        today = Date.utc_today()
        first = %Date{today | day: 1}
        last = Date.end_of_month(today)
        socket |> assign(:date_from, first) |> assign(:date_to, last)
      _ -> socket
    end
  end

  defp shift_range(socket, days) when is_integer(days) do
    socket
    |> assign(:date_from, Date.add(socket.assigns.date_from, days))
    |> assign(:date_to, Date.add(socket.assigns.date_to, days))
  end

  defp shift_month(socket, months) do
    %Date{} = from = socket.assigns.date_from
    %Date{} = to = socket.assigns.date_to
    new_from = shift_date_by_months(from, months)
    new_to = shift_date_by_months(to, months)
    socket |> assign(:date_from, new_from) |> assign(:date_to, new_to)
  end

  defp shift_date_by_months(%Date{} = date, months) when is_integer(months) do
    total_months = date.year * 12 + (date.month - 1) + months
    new_year = div(total_months, 12)
    new_month = rem(total_months, 12) + 1
    days_in_target = Date.days_in_month(%Date{year: new_year, month: new_month, day: 1})
    new_day = min(date.day, days_in_target)
    {:ok, new_date} = Date.new(new_year, new_month, new_day)
    new_date
  end

  defp type_color("meeting_room"), do: "bg-blue-500 text-white"
  defp type_color("vehicle"), do: "bg-green-500 text-white"
  defp type_color("catering"), do: "bg-purple-500 text-white"
  defp type_color("equipment"), do: "bg-orange-500 text-white"
  defp type_color(_), do: "bg-gray-500 text-white"

  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/><.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />
      <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

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

        <!-- Calendar Section -->
        <section class="bg-white p-4 md:p-8 rounded-xl shadow-md">
            <h2 class="text-xl md:text-2xl font-bold mb-6">Kalendar Tempahan</h2>

            <!-- Filter and Navigation Bar -->
            <div class="flex flex-wrap items-center justify-between gap-4 mb-6">
                <div class="flex flex-wrap items-center gap-4">
                    <!-- Dropdown filter -->
                    <form phx-change="filter_type" class="flex items-center space-x-2">
                        <select name="type" value={@filter_type} class="border border-gray-300 pr-8 rounded-lg p-2 text-gray-700 focus:ring-blue-500 focus:border-blue-500">
                            <option value="all">Semua jenis</option>
                            <option value="meeting_room">Bilik mesyuarat</option>
                            <option value="vehicle">Kenderaan</option>
                            <option value="catering">Katering</option>
                            <option value="equipment">Peralatan</option>
                        </select>
                    </form>

                    <!-- Day/Week/Month buttons -->
              <div class="flex items-center space-x-1 border border-gray-300 rounded-lg p-1">
                <button phx-click="set_view" phx-value-view="day" class={"px-4 py-2 font-semibold rounded-lg transition-colors " <> if @view == "day", do: "bg-blue-600 text-white shadow-md", else: "bg-white text-gray-700 hover:bg-gray-200"}>Hari</button>
                <button phx-click="set_view" phx-value-view="week" class={"px-4 py-2 font-semibold rounded-lg transition-colors " <> if @view == "week", do: "bg-blue-600 text-white shadow-md", else: "bg-white text-gray-700 hover:bg-gray-200"}>Minggu</button>
                <button phx-click="set_view" phx-value-view="month" class={"px-4 py-2 font-semibold rounded-lg transition-colors " <> if @view == "month", do: "bg-blue-600 text-white shadow-md", else: "bg-white text-gray-700 hover:bg-gray-200"}>Bulan</button>
              </div>
                </div>

                <!-- Date range pickers -->
            <div class="flex flex-wrap items-center gap-4">
              <form phx-change="set_range" class="flex flex-wrap items-center gap-4">
                <div class="flex items-center space-x-2">
                  <p class="text-gray-700 whitespace-nowrap">Dari</p>
                  <div class="flex items-center border border-gray-300 rounded-lg p-2 bg-white">
                    <input type="date" name="from" value={Date.to_iso8601(@date_from)} class="outline-none w-36 text-gray-700">
                  </div>
                </div>
                <div class="flex items-center space-x-2">
                  <p class="text-gray-700 whitespace-nowrap">Hingga</p>
                  <div class="flex items-center border border-gray-300 rounded-lg p-2 bg-white">
                    <input type="date" name="to" value={Date.to_iso8601(@date_to)} class="outline-none w-36 text-gray-700">
                  </div>
                </div>
              </form>
              <div class="flex items-center gap-2">
                <button phx-click="nav" phx-value-dir="prev" class="px-3 py-2 rounded-lg bg-white border text-gray-700 hover:bg-gray-100">‹</button>
                <button phx-click="nav" phx-value-dir="next" class="px-3 py-2 rounded-lg bg-white border text-gray-700 hover:bg-gray-100">›</button>
              </div>
            </div>
            </div>

            <!-- Calendar Grid -->
            <div class="overflow-x-auto rounded-lg border border-gray-200">
            <div class="min-w-[800px]">
              <div class="grid grid-cols-1 md:grid-cols-7 gap-0">
                <%= for day <- @calendar_days do %>
                  <div class="border-b md:border-b-0 md:border-r border-gray-200 p-4">
                    <div class="flex items-center justify-between mb-3">
                      <div class="text-sm font-semibold text-gray-700"><%= Calendar.strftime(day, "%a") %></div>
                      <div class="text-lg font-bold"><%= day.day %></div>
                    </div>
                    <div class="space-y-2">
                      <%= for ev <- Map.get(@events_by_day, day, []) do %>
                        <div class={"text-xs px-2 py-1 rounded-md shadow-sm " <> type_color(ev.type)}>
                          <div class="font-semibold truncate"><%= ev.title %></div>
                          <div class="opacity-90">
                            <%= Calendar.strftime(ev.usage_at, "%H:%M") %> - <%= Calendar.strftime(ev.return_at, "%H:%M") %>
                          </div>
                        </div>
                      <% end %>
                      <%= if Map.get(@events_by_day, day, []) == [] do %>
                        <div class="text-xs text-gray-400">Tiada acara</div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
            </div>
        </section>

    </body>
      </main>
    </div>
    """
  end
end

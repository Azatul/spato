defmodule SpatoWeb.AdminDashboardLive do
    use SpatoWeb, :live_view
    import SpatoWeb.Components.Sidebar
    import SpatoWeb.Components.Headbar
    use SpatoWeb.NotificationMixin

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

      today = Date.utc_today()
      view_mode = "week"
      {date_from, date_to} = date_range_for_view(view_mode, today)

      socket =
        socket
        |> assign(:page_title, "Admin Dashboard")
        |> assign(:active_tab, "admin_dashboard")
        |> assign(:sidebar_open, true)
        |> assign(:show_notifications, false)
        |> load_notifications()
        |> assign(:vehicle_stats, vehicle_stats)
        |> assign(:catering_stats, catering_stats)
        |> assign(:equipment_stats, equipment_stats)
        |> assign(:meeting_room_stats, meeting_room_stats)
        |> assign(:view_mode, view_mode)
        |> assign(:current_date, today)
        |> assign(:date_from, date_from)
        |> assign(:date_to, date_to)
        |> assign(:booking_filter, "all")

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
      case Spato.Notifications.get_notification(id) do
        %{status: "unread"} = notification ->
          {:ok, _} = Spato.Notifications.mark_as_read(notification)
          socket = load_notifications(socket)
          {:noreply, socket}
        _ ->
          {:noreply, socket}
      end
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
                          <p class="text-3xl font-bold mt-1 text-purple-500"><%= @meeting_room_stats.pending %></p>
                      </div>
                      <div class="w-full flex justify-end">
                          <.link
                          navigate={"/admin/meeting_room_bookings?page=1&q=&status=pending&date="}
                          class="mt-4 inline-flex items-center justify-center px-3 py-1 bg-gradient-to-r from-purple-200 to-purple-300 text-purple-800 font-semibold rounded-lg shadow-md hover:from-purple-300 hover:to-purple-400 transition-all text-sm"
                          >
                          Ambil tindakan →
                          </.link>
                      </div>
                  </div>

                  <!-- Card: Kenderaan (Vehicle) -->
                  <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                      <div>
                          <p class="text-sm text-gray-500">Kenderaan</p>
                          <p class="text-3xl font-bold mt-1 text-orange-500"><%= @vehicle_stats.pending %></p>
                      </div>
                      <div class="w-full flex justify-end">
                          <.link
                          navigate={"/admin/vehicle_bookings?page=1&q=&status=pending&date="}
                          class="mt-4 inline-flex items-center justify-center px-3 py-1 bg-gradient-to-r from-orange-200 to-orange-300 text-orange-800 font-semibold rounded-lg shadow-md hover:from-orange-300 hover:to-orange-400 transition-all text-sm"
                          >
                              Ambil tindakan →
                          </.link>
                      </div>
                  </div>

                  <!-- Card: Katering (Catering) -->
                  <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                      <div>
                          <p class="text-sm text-gray-500">Katering</p>
                          <p class="text-3xl font-bold mt-1 text-rose-500"><%= @catering_stats.pending %></p>
                      </div>
                      <div class="w-full flex justify-end">
                      <.link
                      navigate={"/admin/catering_bookings?page=1&q=&status=pending&date="}
                      class="mt-4 inline-flex items-center justify-center px-3 py-1 bg-gradient-to-r from-rose-200 to-rose-300 text-rose-800 font-semibold rounded-lg shadow-md hover:from-rose-300 hover:to-rose-400 transition-all text-sm"
                      >
                      Ambil tindakan →
                      </.link>
                      </div>
                  </div>

                 <!-- Card: Peralatan (Equipment) -->
                  <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                  <div>
                      <p class="text-sm text-gray-500">Peralatan</p>
                      <p class="text-3xl font-bold mt-1 text-indigo-500"><%= @equipment_stats.pending %></p>
                  </div>
                  <div class="w-full flex justify-end">
                          <.link
                          navigate={"/admin/equipment_bookings?page=1&q=&status=pending&date="}
                          class="mt-4 inline-flex items-center justify-center px-3 py-1 bg-gradient-to-r from-indigo-200 to-indigo-300 text-indigo-800 font-semibold rounded-lg shadow-md hover:from-indigo-300 hover:to-indigo-400 transition-all text-sm"
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
              <div class="mb-6 bg-white p-4 rounded-xl shadow-md w-full">
                <div class="flex flex-wrap items-end justify-between gap-4">
                  <div class="flex flex-wrap items-end gap-4">
                  <!-- Type filter -->
                  <div class="flex items-center space-x-2">
                    <select name="type" phx-change="filter_changed" class="border border-gray-300 rounded-lg pr-8 p-2 text-gray-700 focus:ring-2 focus:ring-purple-300 focus:border-transparent transition-all">
                      <option value="all" selected={@booking_filter == "all"}>Semua Tempahan</option>
                      <option value="meeting_room" selected={@booking_filter == "meeting_room"}>Bilik Mesyuarat</option>
                      <option value="vehicle" selected={@booking_filter == "vehicle"}>Kenderaan</option>
                      <option value="catering" selected={@booking_filter == "catering"}>Katering</option>
                      <option value="equipment" selected={@booking_filter == "equipment"}>Peralatan</option>
                    </select>
                  </div>

                  <!-- View mode -->
                  <div class="flex items-center space-x-1 border border-gray-200 rounded-lg p-1 bg-gray-50">
                    <button phx-click="change_view" phx-value-view="day" class={"px-4 py-2 rounded-lg transition-colors " <> if @view_mode == "day", do: "bg-purple-600 text-white shadow", else: "bg-white text-gray-700 hover:bg-gray-100"}>Hari</button>
                    <button phx-click="change_view" phx-value-view="week" class={"px-4 py-2 rounded-lg transition-colors " <> if @view_mode == "week", do: "bg-purple-600 text-white shadow", else: "bg-white text-gray-700 hover:bg-gray-100"}>Minggu</button>
                    <button phx-click="change_view" phx-value-view="month" class={"px-4 py-2 rounded-lg transition-colors " <> if @view_mode == "month", do: "bg-purple-600 text-white shadow", else: "bg-white text-gray-700 hover:bg-gray-100"}>Bulan</button>
                  </div>
                  </div>

                  <!-- Date range and navigation -->
                  <div class="flex flex-wrap items-end gap-4">
                  <div class="flex items-center space-x-2">
                      <label class="text-sm text-gray-600">Dari</label>
                      <input name="from" type="date" value={@date_from} phx-change="filter_changed" class="border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-purple-300 focus:border-transparent transition-all w-44" />
                    </div>
                    <div class="flex items-center space-x-2">
                      <label class="text-sm text-gray-600">Hingga</label>
                      <input name="to" type="date" value={@date_to} phx-change="filter_changed" class="border border-gray-300 rounded-lg p-2 focus:ring-2 focus:ring-purple-300 focus:border-transparent transition-all w-44" />
                    </div>
                    <div class="flex items-center space-x-2">
                      <button phx-click="navigate" phx-value-dir="prev" class="px-3 py-2 rounded-lg bg-gray-900 text-white hover:bg-gray-700 transition">‹</button>
                      <button phx-click="navigate" phx-value-dir="today" class="px-3 py-2 rounded-lg bg-white border border-gray-200 hover:bg-gray-100">Hari ini</button>
                      <button phx-click="navigate" phx-value-dir="next" class="px-3 py-2 rounded-lg bg-gray-900 text-white hover:bg-gray-700 transition">›</button>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Calendar Grid -->
              <div class="overflow-x-auto rounded-xl border border-gray-200 bg-white">
                <%= if @view_mode == "day" do %>
                  <.day_view calendar_data={@calendar_data} />
                <% end %>

                <%= if @view_mode == "week" do %>
                  <.week_view calendar_data={@calendar_data} />
                <% end %>

                <%= if @view_mode == "month" do %>
                  <.month_view calendar_data={@calendar_data} />
                <% end %>
              </div>
          </section>

      </body>
        </main>
      </div>
      """
    end

  # -- Components --
  attr :calendar_data, :any, required: true
  defp day_view(assigns) do
    ~H"""
    <div class="p-4">
      <div class="text-lg font-semibold mb-3">Hari</div>
      <div class="space-y-2">
        <%= for slot <- Enum.sort_by(@calendar_data, & &1.time_slot) do %>
          <div class="border rounded-lg p-3 bg-gray-50">
            <div class="text-sm text-gray-600 mb-2">
              <%= elem(slot.time_slot, 0) %>:<%= Integer.to_string(elem(slot.time_slot, 1)) |> String.pad_leading(2, "0") %>
            </div>
            <div class="grid md:grid-cols-2 lg:grid-cols-3 gap-2">
              <%= for b <- slot.bookings do %>
                <.booking_chip booking={b} />
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :calendar_data, :any, required: true
  defp week_view(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-7">
      <%= for day <- @calendar_data do %>
        <div class="border p-3 min-h-40">
          <div class="flex items-baseline justify-between mb-2">
            <div class="text-sm text-gray-600"><%= day_name(day.date) %></div>
            <div class="text-lg font-semibold"><%= day.date.day %></div>
          </div>
          <div class="space-y-2">
            <%= for b <- day.bookings do %>
              <.booking_chip booking={b} />
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :calendar_data, :any, required: true
  defp month_view(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-7">
      <%= for day <- @calendar_data do %>
        <div class="border p-3 min-h-40">
          <div class="flex items-baseline justify-between mb-2">
            <div class="text-sm text-gray-600"><%= day_name(day.date) %></div>
            <div class="text-lg font-semibold"><%= day.date.day %></div>
          </div>
          <div class="space-y-2">
            <%= for b <- day.bookings do %>
              <.booking_chip booking={b} />
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :booking, :any, required: true
  defp booking_chip(assigns) do
    ~H"""
    <div class={"text-xs px-2 py-1 rounded-md border inline-flex items-center gap-2 " <> booking_color(@booking.type)}>
      <span class="font-semibold capitalize"><%= human_type(@booking.type) %></span>
      <span class="text-gray-700"><%= @booking.title %></span>
    </div>
    """
  end

  defp booking_color("vehicle"), do: "bg-orange-50 border-orange-200 text-orange-800"
  defp booking_color("catering"), do: "bg-rose-50 border-rose-200 text-rose-800"
  defp booking_color("equipment"), do: "bg-indigo-50 border-indigo-200 text-indigo-800"
  defp booking_color("meeting_room"), do: "bg-purple-50 border-purple-200 text-purple-800"
  defp booking_color(_), do: "bg-gray-50 border-gray-200 text-gray-800"

  defp human_type("vehicle"), do: "Kenderaan"
  defp human_type("catering"), do: "Katering"
  defp human_type("equipment"), do: "Peralatan"
  defp human_type("meeting_room"), do: "Bilik Mesyuarat"
  defp human_type(other), do: other

  def handle_event("change_view", %{"view" => view}, socket) do
    view_mode = view
    current_date = socket.assigns.current_date
    {date_from, date_to} = date_range_for_view(view_mode, current_date)

    socket =
      socket
      |> assign(:view_mode, view_mode)
      |> assign(:date_from, date_from)
      |> assign(:date_to, date_to)
      |> load_calendar()

    {:noreply, socket}
  end

  def handle_event("navigate", %{"dir" => dir}, socket) do
    %{current_date: current_date, view_mode: view_mode} = socket.assigns

    new_date =
      case {view_mode, dir} do
        {_, "today"} -> Date.utc_today()
        {"day", "prev"} -> Date.add(current_date, -1)
        {"day", "next"} -> Date.add(current_date, 1)
        {"week", "prev"} -> Date.add(current_date, -7)
        {"week", "next"} -> Date.add(current_date, 7)
        {"month", "prev"} -> Date.add(Date.beginning_of_month(current_date), -1)
        {"month", "next"} -> Date.add(Date.end_of_month(current_date), 1)
        _ -> current_date
      end

    {date_from, date_to} = date_range_for_view(view_mode, new_date)

    socket =
      socket
      |> assign(:current_date, new_date)
      |> assign(:date_from, date_from)
      |> assign(:date_to, date_to)
      |> load_calendar()

    {:noreply, socket}
  end

  def handle_event("filter_changed", params, socket) do
    type = Map.get(params, "type", socket.assigns.booking_filter)
    from_str = Map.get(params, "from", Date.to_iso8601(socket.assigns.date_from))
    to_str = Map.get(params, "to", Date.to_iso8601(socket.assigns.date_to))

    date_from = parse_date_or(socket.assigns.date_from, from_str)
    date_to = parse_date_or(socket.assigns.date_to, to_str)

    socket =
      socket
      |> assign(:booking_filter, type)
      |> assign(:date_from, date_from)
      |> assign(:date_to, date_to)
      |> load_calendar()

    {:noreply, socket}
  end

  defp parse_date_or(fallback, nil), do: fallback
  defp parse_date_or(fallback, ""), do: fallback
  defp parse_date_or(_fallback, iso) do
    case Date.from_iso8601(iso) do
      {:ok, d} -> d
      _ -> Date.utc_today()
    end
  end

  defp date_range_for_view("day", date) do
    {date, date}
  end

  defp date_range_for_view("week", date) do
    {Date.beginning_of_week(date), Date.end_of_week(date)}
  end

  defp date_range_for_view("month", date) do
    {Date.beginning_of_month(date), Date.end_of_month(date)}
  end

  defp date_range_for_view(_other, date), do: date_range_for_view("week", date)

  defp load_calendar(socket) do
    %{date_from: date_from, date_to: date_to, booking_filter: booking_filter, view_mode: view_mode} = socket.assigns

    {:ok, start_dt} = DateTime.new(date_from, ~T[00:00:00], "Etc/UTC")
    {:ok, end_dt} = DateTime.new(date_to, ~T[23:59:59], "Etc/UTC")

    bookings = Spato.Bookings.list_approved_bookings_in_range(start_dt, end_dt)

    bookings =
      case booking_filter do
        "all" -> bookings
        other -> Enum.filter(bookings, fn b -> b.type == other end)
      end

    calendar_data =
      case view_mode do
        "day" -> build_day_view(bookings, date_from)
        "week" -> build_week_view(bookings, date_from)
        "month" -> build_month_view(bookings, date_from)
        _ -> build_week_view(bookings, date_from)
      end

    socket
    |> assign(:bookings, bookings)
    |> assign(:calendar_data, calendar_data)
  end

  defp build_day_view(bookings, date) do
    {:ok, day_start} = DateTime.new(date, ~T[00:00:00], "Etc/UTC")
    {:ok, day_end} = DateTime.new(date, ~T[23:59:59], "Etc/UTC")

    day_bookings = Enum.filter(bookings, &overlaps_day?(&1, date, day_start, day_end))

    # Group by hour slot
    day_bookings
    |> Enum.group_by(fn b ->
      dt = b.usage_at
      {dt.hour, if(dt.minute < 30, do: 0, else: 30)}
    end)
    |> Enum.map(fn {{hour, minute}, booking_list} ->
      %{date: date, time_slot: {hour, minute}, bookings: booking_list}
    end)
    |> Enum.sort_by(& &1.time_slot)
  end

  defp build_week_view(bookings, start_date) do
    week_start = Date.beginning_of_week(start_date)
    week_end = Date.end_of_week(start_date)

    Enum.map(Date.range(week_start, week_end), fn date ->
      {:ok, day_start} = DateTime.new(date, ~T[00:00:00], "Etc/UTC")
      {:ok, day_end} = DateTime.new(date, ~T[23:59:59], "Etc/UTC")
      day_bookings = Enum.filter(bookings, &overlaps_day?(&1, date, day_start, day_end))
      %{date: date, bookings: day_bookings}
    end)
  end

  defp build_month_view(bookings, start_date) do
    month_start = Date.beginning_of_month(start_date)
    month_end = Date.end_of_month(start_date)

    Enum.map(Date.range(month_start, month_end), fn date ->
      {:ok, day_start} = DateTime.new(date, ~T[00:00:00], "Etc/UTC")
      {:ok, day_end} = DateTime.new(date, ~T[23:59:59], "Etc/UTC")
      day_bookings = Enum.filter(bookings, &overlaps_day?(&1, date, day_start, day_end))
      %{date: date, bookings: day_bookings}
    end)
  end

  defp overlaps_day?(booking, _date, day_start, day_end) do
    usage_at = booking.usage_at
    return_at = booking.return_at
    DateTime.compare(usage_at, day_end) == :lt and DateTime.compare(return_at, day_start) == :gt
  end

  defp day_name(%Date{} = d) do
    case Date.day_of_week(d) do
      1 -> "Isnin"
      2 -> "Selasa"
      3 -> "Rabu"
      4 -> "Khamis"
      5 -> "Jumaat"
      6 -> "Sabtu"
      7 -> "Ahad"
    end
  end

  defp month_name(%Date{} = d) do
    case d.month do
      1 -> "Januari"
      2 -> "Februari"
      3 -> "Mac"
      4 -> "April"
      5 -> "Mei"
      6 -> "Jun"
      7 -> "Julai"
      8 -> "Ogos"
      9 -> "September"
      10 -> "Oktober"
      11 -> "November"
      12 -> "Disember"
    end
  end
end

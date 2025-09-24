defmodule SpatoWeb.AdminDashboardLive do
    use SpatoWeb, :live_view
    import SpatoWeb.Components.Sidebar
    import SpatoWeb.Components.Headbar
    alias Spato.Bookings

    on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

    def mount(_params, _session, socket) do
      if socket.assigns.current_user.role != "admin" do
        {:halt,
         socket
         |> put_flash(:error, "Access denied")
         |> redirect(to: "/dashboard")}
      else
        today = Date.utc_today()

        start_date = Date.beginning_of_week(today)
        end_date = Date.end_of_week(today)

        {:ok, start_dt} = DateTime.new(start_date, ~T[00:00:00], "Etc/UTC")
        {:ok, end_dt} = DateTime.new(end_date, ~T[23:59:59], "Etc/UTC")

        bookings = Bookings.list_approved_bookings_in_range(start_dt, end_dt)

        {:ok,
         socket
         |> assign(:page_title, "Admin Dashboard")
         |> assign(:active_tab, "admin_dashboard")
         |> assign(:sidebar_open, true)
         |> assign(:bookings, bookings)
         |> assign(:filter_view, "week")
         |> assign(:filter_type, "all")
         |> assign(:start_date, start_date)
         |> assign(:end_date, end_date)}
      end
    end

    def handle_event("toggle_sidebar", _params, socket) do
      {:noreply, update(socket, :sidebar_open, &(!&1))}
    end

    def handle_event("set_view", %{"view" => view}, socket) do
      {:noreply, assign(socket, :filter_view, view)}
    end

    def handle_event("set_type", %{"type" => type}, socket) do
      {:noreply, assign(socket, :filter_type, type)}
    end

    def render(assigns) do
      ~H"""
      <div class="flex h-screen">
        <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
        <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

        <main class="flex-1 pt-20 p-6 transition-all duration-300">
          <body class="bg-gray-100 p-4 md:p-8">

            <!-- Top Section: Today's Reservations -->
            <section class="mb-8">
              <h2 class="text-xl md:text-2xl font-bold mb-4">Tempahan hari ini</h2>
              <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">

                <!-- Card: Meeting Room -->
                <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                  <div>
                    <p class="text-sm text-gray-500">Bilik mesyuarat</p>
                    <p class="text-3xl font-bold mt-1">12</p>
                  </div>
                  <div class="w-full flex justify-end">
                    <.link
                      patch={if @current_user.role == "admin", do: "/admin/meeting_rooms_bookings", else: "/meeting_rooms_bookings"}
                      class="flex items-center gap-2 px-3 py-1.5 bg-blue-50 text-blue-600 hover:bg-blue-100 font-medium rounded-full transition-colors text-sm">
                      Lihat senarai
                      <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                      </svg>
                    </.link>
                  </div>
                </div>

                <!-- Card: Vehicle -->
                <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                  <div>
                    <p class="text-sm text-gray-500">Kenderaan</p>
                    <p class="text-3xl font-bold mt-1">8</p>
                  </div>
                  <div class="w-full flex justify-end">
                    <.link
                      patch={if @current_user.role == "admin", do: "/admin/vehicle_bookings", else: "/vehicle_bookings"}
                      class="flex items-center gap-2 px-3 py-1.5 bg-blue-50 text-blue-600 hover:bg-blue-100 font-medium rounded-full transition-colors text-sm">
                      Lihat senarai
                      <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                      </svg>
                    </.link>
                  </div>
                </div>

                <!-- Card: Catering -->
                <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                  <div>
                    <p class="text-sm text-gray-500">Katering</p>
                    <p class="text-3xl font-bold mt-1">4</p>
                  </div>
                  <div class="w-full flex justify-end">
                    <.link
                      patch={if @current_user.role == "admin", do: "/admin/catering_bookings", else: "/catering_bookings"}
                      class="flex items-center gap-2 px-3 py-1.5 bg-blue-50 text-blue-600 hover:bg-blue-100 font-medium rounded-full transition-colors text-sm">
                      Lihat senarai
                      <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                      </svg>
                    </.link>
                  </div>
                </div>

                <!-- Card: Equipment -->
                <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                  <div>
                    <p class="text-sm text-gray-500">Peralatan</p>
                    <p class="text-3xl font-bold mt-1">12</p>
                  </div>
                  <div class="w-full flex justify-end">
                    <.link
                      patch={if @current_user.role == "admin", do: "/admin/equipment_bookings", else: "/equipment_bookings"}
                       class="flex items-center gap-2 px-3 py-1.5 bg-blue-50 text-blue-600 hover:bg-blue-100 font-medium rounded-full transition-colors text-sm">
                      Lihat senarai
                      <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"/>
                      </svg>
                    </.link>
                  </div>
                </div>
              </div>
            </section>

            <!-- Calendar Section -->
            <section class="bg-white p-4 md:p-8 rounded-xl shadow-md">
              <h2 class="text-xl md:text-2xl font-bold mb-6">Kalendar Tempahan</h2>

              <!-- Filters -->
              <div class="flex flex-wrap items-center justify-between gap-4 mb-6">
                <div class="flex items-center gap-2">
                  <select phx-change="set_type" name="type" class="border border-gray-300 rounded-lg p-2 text-gray-700 focus:ring-blue-500 focus:border-blue-500">
                    <option value="all" selected={@filter_type == "all"}>Semua</option>
                    <option value="vehicle" selected={@filter_type == "vehicle"}>Kenderaan</option>
                    <option value="equipment" selected={@filter_type == "equipment"}>Peralatan</option>
                  </select>
                </div>

                <div class="flex items-center space-x-1 border border-gray-300 rounded-lg p-1">
                  <button phx-click="set_view" phx-value-view="day" class={"px-4 py-2 rounded #{if @filter_view == "day", do: "bg-blue-600 text-white", else: "bg-white text-gray-700"}"}>Hari</button>
                  <button phx-click="set_view" phx-value-view="week" class={"px-4 py-2 rounded #{if @filter_view == "week", do: "bg-blue-600 text-white", else: "bg-white text-gray-700"}"}>Minggu</button>
                  <button phx-click="set_view" phx-value-view="month" class={"px-4 py-2 rounded #{if @filter_view == "month", do: "bg-blue-600 text-white", else: "bg-white text-gray-700"}"}>Bulan</button>
                </div>
              </div>

              <!-- Calendar -->
              <%= case @filter_view do %>
                <% "week" -> %>
                  <div class="grid grid-cols-7 gap-4">
                    <%= for day <- Date.range(@start_date, @end_date) do %>
                      <div class="bg-gray-50 p-3 rounded-lg shadow-sm">
                        <p class="font-semibold text-sm"><%= Calendar.strftime(day, "%A %d/%m") %></p>
                        <ul class="mt-2 space-y-1">
                          <%= for booking <- Enum.filter(@bookings, fn b ->
                                Date.compare(DateTime.to_date(b.usage_at), day) in [:lt, :eq] and
                                Date.compare(DateTime.to_date(b.return_at), day) in [:gt, :eq] and
                                (@filter_type == "all" or b.type == @filter_type)
                              end) do %>
                            <li class={[
                              "text-xs px-2 py-1",
                              booking.type == "vehicle" && "bg-green-100 text-green-700",
                              booking.type == "equipment" && "bg-red-100 text-red-700",
                              DateTime.to_date(booking.usage_at) == day && "rounded-l-md",
                              DateTime.to_date(booking.return_at) == day && "rounded-r-md"
                            ]}>
                              <%= booking.title %>
                              (<%= Calendar.strftime(booking.usage_at, "%H:%M") %>–<%= Calendar.strftime(booking.return_at, "%H:%M") %>)
                            </li>
                          <% end %>
                        </ul>
                      </div>
                    <% end %>
                  </div>
                <% _ -> %>
                  <p class="text-gray-500 italic">View not implemented yet.</p>
              <% end %>
            </section>
          </body>
        </main>
      </div>
      """
    end
  end

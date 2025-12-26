defmodule SpatoWeb.EquipmentBookingLive.AdminIndex do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar
  use SpatoWeb.NotificationMixin

  alias Spato.Bookings
  alias Spato.Accounts.User

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, "admin_equipments")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:filter_status, "all")
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:filter_date, "")
     |> assign(:show_reject_modal, false)
     |> assign(:reject_booking, nil)
     |> assign(:show_edit_modal, false)
     |> assign(:selected_status, nil)
     |> assign(:reason, nil)
     |> assign(:edit_booking, nil)
     |> assign(:show_approve_modal, false)
     |> assign(:approve_booking, nil)
     |> assign(:show_notifications, false)
     |> load_notifications()
     |> assign(:stats, Bookings.get_equipment_booking_stats())
     |> load_equipment_bookings()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page   = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "q", "")
    status = Map.get(params, "status", "all")
    date   = Map.get(params, "date", "")

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:search_query, search)
     |> assign(:filter_status, status)
     |> assign(:filter_date, date)
     |> load_equipment_bookings()
     |> apply_action(socket.assigns.live_action, params)}
  end

  # --- EVENTS ---

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    booking = Bookings.get_equipment_booking!(id)
    {:ok, _} = Bookings.approve_equipment_booking(booking)
    updated = Bookings.get_equipment_booking!(id)
    {:noreply,
     socket
     |> assign(:live_action, nil)
     |> replace_equipment_booking_in_list(updated)
     |> assign(:stats, Bookings.get_equipment_booking_stats())
     |> put_flash(:info, "Tempahan telah diluluskan")}
  end

  @impl true
  def handle_event("reject", %{"id" => id}, socket) do
    booking = Bookings.get_equipment_booking!(id)
    {:ok, _} = Bookings.reject_equipment_booking(booking)
    updated = Bookings.get_equipment_booking!(id)
    {:noreply,
     socket
     |> assign(:live_action, nil)
     |> replace_equipment_booking_in_list(updated)
     |> assign(:stats, Bookings.get_equipment_booking_stats())
     |> put_flash(:info, "Tempahan telah ditolak")}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  # Notification events
  @impl true
  def handle_event("toggle_notifications", params, socket) do
    handle_toggle_notifications(params, socket)
  end

  @impl true
  def handle_event("read_notification", params, socket) do
    handle_read_notification(params, socket)
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 1)
     |> load_equipment_bookings()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
      push_patch(socket,
        to: ~p"/admin/equipment_bookings?page=1&q=#{socket.assigns.search_query}&status=#{status}&date=#{socket.assigns.filter_date}") }
  end

  @impl true
  def handle_event("filter_date", %{"date" => date}, socket) do
    {:noreply,
      push_patch(socket,
        to: ~p"/admin/equipment_bookings?page=1&q=#{socket.assigns.search_query}&status=#{socket.assigns.filter_status}&date=#{date}") }
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, String.to_integer(page))
     |> load_equipment_bookings()}
  end

  @impl true
  def handle_event("open_reject_modal", %{"id" => id}, socket) do
    booking =
      Bookings.get_equipment_booking!(id)
      |> Spato.Repo.preload([:user, :equipment, user: [:user_profile, user_profile: [:department]]])
    {:noreply, socket |> assign(:reject_booking, booking) |> assign(:show_reject_modal, true)}
  end

  @impl true
  def handle_event("submit_rejection", %{"reason" => reason}, socket) do
    {:ok, _} = Bookings.reject_equipment_booking(socket.assigns.reject_booking, reason)
    updated = Bookings.get_equipment_booking!(socket.assigns.reject_booking.id)
    {:noreply,
     socket
     |> assign(:show_reject_modal, false)
     |> assign(:reject_booking, nil)
     |> replace_equipment_booking_in_list(updated)
     |> assign(:stats, Bookings.get_equipment_booking_stats())
     |> put_flash(:info, "Tempahan telah ditolak")
     |> assign(:live_action, nil)}
  end

  @impl true
  def handle_event("status_changed", %{"status" => status}, socket) do
    {:noreply, socket |> assign(:selected_status, status) |> assign(:live_action, nil)}
  end

  @impl true
  def handle_event("open_edit_modal", %{"id" => id}, socket) do
    booking = Bookings.get_equipment_booking!(id)
    {:noreply, socket |> assign(:edit_booking, booking) |> assign(:show_edit_modal, true) |> assign(:live_action, nil)}
  end

  @impl true
  def handle_event("update_status", %{"status" => status} = params, socket) do
    reason = Map.get(params, "reason")

    update_params =
      case status do
        "rejected" -> %{status: status, rejection_reason: reason}
        _ -> %{status: status, rejection_reason: nil}
      end

    {:ok, _booking} = Bookings.update_equipment_booking(socket.assigns.edit_booking, update_params)
    updated = Bookings.get_equipment_booking!(socket.assigns.edit_booking.id)

    {:noreply,
     socket
     |> assign(:show_edit_modal, false)
     |> replace_equipment_booking_in_list(updated)
     |> assign(:stats, Bookings.get_equipment_booking_stats())
     |> assign(:selected_status, nil)
     |> assign(:live_action, nil)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_reject_modal, false)
     |> assign(:reject_booking, nil)
     |> assign(:show_edit_modal, false)
     |> assign(:edit_booking, nil)
     |> assign(:show_approve_modal, false)
     |> assign(:approve_booking, nil)
     |> assign(:live_action, nil)}
  end

  @impl true
  def handle_event("open_approve_modal", %{"id" => id}, socket) do
    booking =
      Bookings.get_equipment_booking!(id)
      |> Spato.Repo.preload([:user, :equipment, user: [:user_profile]])

    {:noreply,
    socket
    |> assign(:approve_booking, booking)
    |> assign(:show_approve_modal, true)}
  end

  @impl true
  def handle_event("confirm_approve", _params, socket) do
    booking = socket.assigns.approve_booking
    {:ok, _} = Bookings.approve_equipment_booking(booking)
    updated = Bookings.get_equipment_booking!(booking.id)

    {:noreply,
    socket
    |> assign(:show_approve_modal, false)
    |> assign(:approve_booking, nil)
    |> replace_equipment_booking_in_list(updated)
    |> assign(:stats, Bookings.get_equipment_booking_stats())
    |> put_flash(:info, "Tempahan telah diluluskan")}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Butiran Tempahan Peralatan")
    |> assign(:equipment_booking, Bookings.get_equipment_booking!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Senarai Tempahan Peralatan")
    |> assign(:equipment_booking, nil)
  end

  # --- LOAD BOOKINGS ---

  defp load_equipment_bookings(socket) do
    params = %{
      "page" => socket.assigns.page,
      "search" => socket.assigns.search_query,
      "status" => socket.assigns.filter_status,
      "date" => socket.assigns.filter_date
    }

    data = Bookings.list_equipment_bookings_paginated(params)

    socket
    |> assign(:equipment_bookings_page, data.equipment_bookings_page)
    |> assign(:total_pages, data.total_pages)
    |> assign(:filtered_count, data.total)
    |> assign(:stats, Bookings.get_equipment_booking_stats())
    |> assign(:page, data.page)
  end

  defp replace_equipment_booking_in_list(socket, %{} = updated_booking) do
    list =
      Enum.map(socket.assigns.equipment_bookings_page, fn b ->
        if b.id == updated_booking.id, do: updated_booking, else: b
      end)

    socket |> assign(:equipment_bookings_page, list)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
      <div class="flex flex-col flex-1">
        <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} notifications={@notifications} unread_count={@unread_count} show_notifications={@show_notifications} />

        <main class="flex-1 overflow-y-auto pt-20 p-6 transition-all duration-300 bg-gray-100">
          <section class="mb-4">
            <!-- Page Title -->
            <h1 class="text-xl font-bold mb-1">Tempahan Peralatan</h1>
            <p class="text-md text-gray-500 mb-4">Semak dan urus semua tempahan peralatan dalam sistem</p>

            <!-- Stats Cards -->
            <div class="flex flex-wrap gap-4 mb-4">
              <%= for {label, value} <- [
                    {"Jumlah Tempahan", @stats.total},
                    {"Menunggu Kelulusan", @stats.pending},
                    {"Diluluskan", @stats.approved},
                    {"Aktif", @stats.active}
                  ] do %>
                <% card_colors = case label do
                  "Jumlah Tempahan" -> %{border: "border-purple-300", bg: "bg-purple-100", icon: "text-purple-500", icon_class: "fa-solid fa-calendar-days"}
                  "Menunggu Kelulusan" -> %{border: "border-amber-300", bg: "bg-amber-100", icon: "text-amber-500", icon_class: "fa-solid fa-clock"}
                  "Diluluskan" -> %{border: "border-teal-300", bg: "bg-teal-100", icon: "text-teal-500", icon_class: "fa-solid fa-check-circle"}
                  "Aktif" -> %{border: "border-purple-300", bg: "bg-purple-100", icon: "text-purple-500", icon_class: "fa-solid fa-check-double"}
                end %>
                <div class={"flex-1 min-w-[180px] bg-white p-6 rounded-xl shadow-md flex justify-between items-center min-h-[130px] border-l-4 #{card_colors.border} transition-transform hover:scale-105"}>
                  <div>
                    <h3 class="text-gray-600 text-sm font-semibold"><%= label %></h3>
                    <p class="text-4xl font-bold text-gray-800 mt-2"><%= value %></p>
                  </div>
                  <div class={"#{card_colors.bg} p-3 rounded-full"}>
                    <i class={"#{card_colors.icon_class} #{card_colors.icon} text-2xl"}></i>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Table Section -->
            <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
              <div class="flex items-center justify-between mb-4">
                <h2 class="text-lg font-semibold text-gray-900">Senarai Tempahan Peralatan</h2>
              </div>

              <!-- Search & Filters -->
              <div class="flex flex-wrap gap-2 mb-4">
                <!-- Search -->
                <form phx-change="search" class="flex-1 min-w-[200px]">
                  <div class="relative">
                    <!-- Magnifying glass icon -->
                    <.icon name="hero-magnifying-glass" class="absolute left-2 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />

                    <!-- Input -->
                    <input type="text" name="q" value={@search_query} placeholder="Cari peralatan, nombor siri, nama pengguna..." class="w-full border rounded-md pl-8 pr-2 py-1 text-sm"/>
                  </div>
                </form>

                <!-- Date Filter -->
                <form phx-change="filter_date">
                    <input type="date" name="date" value={@filter_date} class="border rounded-md pl-8 pr-2 py-1 text-sm"/>
                </form>

                <!-- Status Filter -->
                <form phx-change="filter_status">
                  <div class="relative">
                    <!-- Funnel icon -->
                    <.icon name="hero-funnel" class="absolute left-2 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />

                    <!-- Select -->
                    <select name="status" class="border rounded-md pl-8 pr-8 py-1 text-sm">
                    <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                    <option value="pending" selected={@filter_status == "pending"}>Menunggu</option>
                    <option value="approved" selected={@filter_status == "approved"}>Diluluskan</option>
                  </select>
                  </div>
                </form>
              </div>

              <!-- Count Message -->
              <div class="mb-2 text-sm text-gray-600">
                <%= if @filtered_count == 0 do %>
                  Tiada tempahan ditemui
                <% else %>
                  <%= @filtered_count %> tempahan ditemui
                <% end %>
              </div>

              <!-- Bookings Table -->
              <.table id="admin_equipment_bookings" rows={@equipment_bookings_page} row_click={fn booking -> JS.patch(
                ~p"/admin/equipment_bookings/#{booking.id}?action=show&page=#{@page}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"
              ) end}>
                <:col :let={booking} label="ID"><%= booking.id %></:col>
                <:col :let={booking} label="Peralatan">
                  <%= if booking.equipment do %>
                    <div class="flex flex-col">
                      <div class="font-semibold text-gray-900"><%= booking.equipment.name %></div>
                      <div class="text-sm text-gray-500">No. Siri: <%= booking.equipment.serial_number %></div>
                    </div>
                  <% else %>
                    <span class="text-gray-400"></span>
                  <% end %>
                </:col>
                <:col :let={booking} label="Dibuat Oleh">
                  <%= if booking.user do %>
                    <div class="flex flex-col">
                      <span class="font-medium text-gray-900"><%= User.display_name(booking.user) %></span>
                      <%= if booking.user.user_profile && booking.user.user_profile.department do %>
                        <span class="text-sm text-gray-500"><%= booking.user.user_profile.department.name %></span>
                      <% end %>
                    </div>
                  <% else %>
                    <span class="text-gray-400"></span>
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
                <span class={"px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
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
                <%= if booking.status == "rejected" do %>
                  <%= if booking.rejection_reason do %>
                    <p class="text-xs text-gray-500">Sebab: <%= booking.rejection_reason %></p>
                  <% end %>
                <% end %>
                <%= if booking.status == "cancelled" do %>
                  <%= if booking.rejection_reason do %>
                    <p class="text-xs text-gray-500">Sebab: <%= booking.rejection_reason %></p>
                  <% end %>
                <% end %>
              </:col>

                <:action :let={booking}>
                  <%= case booking.status do %>
                    <% "pending" -> %>
                      <!-- Approve -->
                      <button phx-click="open_approve_modal" phx-value-id={booking.id}
                        class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-green-600 hover:bg-green-700 text-white"
                        title="Luluskan">
                        <.icon name="hero-check" class="w-4 h-4" />
                      </button>

                      <!-- Reject -->
                      <button phx-click="open_reject_modal" phx-value-id={booking.id}
                        class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-red-600 hover:bg-red-700 text-white ml-2"
                        title="Tolak">
                        <.icon name="hero-x-mark" class="w-4 h-4" />
                      </button>

                    <% "approved" -> %>
                      <button
                        phx-click="open_edit_modal"
                        phx-value-id={booking.id}
                        class="px-3 py-1 text-xs bg-blue-500 hover:bg-blue-600 text-white rounded-md">
                        Ubah Status
                      </button>
                    <% _ -> %>
                      <span class="text-gray-500"></span>
                  <% end %>
                </:action>
              </.table>

              <!-- Pagination -->
              <%= if @filtered_count >= 1 do %>
                <div class="relative flex items-center mt-4">
                  <!-- Previous -->
                  <div class="flex-1">
                    <.link patch={~p"/admin/equipment_bookings?page=#{max(@page - 1, 1)}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                      class={"px-3 py-1 border rounded " <>
                        if @page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Sebelumnya
                    </.link>
                  </div>

                  <!-- Page Numbers -->
                  <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
                    <%= for p <- 1..@total_pages do %>
                      <.link patch={~p"/admin/equipment_bookings?page=#{p}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                        class={"px-3 py-1 border rounded " <>
                          if p == @page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                        <%= p %>
                      </.link>
                    <% end %>
                  </div>

                  <!-- Next -->
                  <div class="flex-1 text-right">
                    <.link patch={~p"/admin/equipment_bookings?page=#{min(@page + 1, @total_pages)}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                      class={"px-3 py-1 border rounded " <>
                        if @page == @total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Seterusnya
                    </.link>
                  </div>
                </div>
              <% end %>
            </section>

            <!-- Modal: Show booking -->
            <.modal :if={@live_action == :show} id="admin-equipment-booking-show" show
              on_cancel={JS.patch(~p"/admin/equipment_bookings?page=#{@page}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}")}>
              <.live_component
                module={SpatoWeb.EquipmentBookingLive.AdminShowComponent}
                id={@equipment_booking.id}
                equipment_booking={@equipment_booking}
              />
              <!-- Modal Footer: Action Buttons -->
              <div class="flex justify-end gap-2 mt-4">
                <%= case @equipment_booking.status do %>
                  <% "pending" -> %>
                    <button
                      phx-click="open_approve_modal"
                      phx-value-id={@equipment_booking.id}
                      class="px-2 py-1 bg-green-600 text-white rounded hover:bg-green-700"
                    >
                      Luluskan
                    </button>

                    <button
                      phx-click="open_reject_modal"
                      phx-value-id={@equipment_booking.id}
                      class="px-2 py-1 bg-red-600 text-white rounded hover:bg-red-700"
                    >
                      Tolak
                    </button>

                  <% "approved" -> %>
                    <button
                      phx-click="open_edit_modal"
                      phx-value-id={@equipment_booking.id}
                      class="px-2 py-1 bg-blue-600 text-white rounded hover:bg-blue-700"
                    >
                      Ubah Status
                    </button>

                  <% "rejected" -> %>
                    <%= if @equipment_booking.rejection_reason do %>
                      <p class="text-sm text-gray-500">Sebab: <%= @equipment_booking.rejection_reason %></p>
                    <% end %>

                  <% "completed" -> %>
                    <span class="text-sm text-blue-600">Selesai</span>

                  <% "cancelled" -> %>
                    <%= if @equipment_booking.rejection_reason do %>
                      <p class="text-sm text-gray-500">Sebab: <%= @equipment_booking.rejection_reason %></p>
                    <% end %>

                  <% _ -> %>
                    <span class="text-gray-500">—</span>
                <% end %>
              </div>
            </.modal>

            <!-- Modal: Reject with reason -->
            <.modal :if={@show_reject_modal} id="reject-equipment-modal" show on_cancel={JS.push("close_modal")}>
              <h2 class="text-lg font-semibold mb-2">Sebab Penolakan</h2>
              <%= if @reject_booking do %>
                <div class="text-sm text-gray-700 space-y-1 mb-3">
                  <%= if @reject_booking.equipment do %>
                    <p>
                      <b>Peralatan:</b>
                      <%= @reject_booking.equipment.name %>
                      (SN: <%= @reject_booking.equipment.serial_number %>)
                    </p>
                  <% end %>
                  <%= if @reject_booking.user do %>
                    <p><b>Pengguna:</b> <%= User.display_name(@reject_booking.user) %></p>
                  <% end %>
                  <p><b>Lokasi:</b> <%= @reject_booking.location %></p>
                  <p><b>Tarikh Guna:</b> <%= Calendar.strftime(@reject_booking.usage_at, "%d-%m-%Y %H:%M") %></p>
                  <p><b>Tarikh Pulang:</b> <%= Calendar.strftime(@reject_booking.return_at, "%d-%m-%Y %H:%M") %></p>
                  <p><b>Kuantiti:</b> <%= @reject_booking.requested_quantity %> unit</p>
                </div>
              <% end %>
              <form phx-submit="submit_rejection" class="space-y-3">
                <textarea name="reason" rows="3" class="w-full border rounded-md p-2 text-sm" placeholder="Nyatakan sebab penolakan..."></textarea>
                <div class="flex justify-end gap-2">
                  <button type="submit" class="px-3 py-1 bg-red-600 text-white rounded-md">Tolak</button>
                  <button type="button" phx-click="close_modal" class="px-3 py-1 border rounded-md">Batal</button>
                </div>
              </form>
            </.modal>

            <!-- Modal: Edit status -->
            <.modal :if={@show_edit_modal} id="edit-equipment-modal" show on_cancel={JS.push("close_modal")}>
              <h2 class="text-lg font-semibold mb-2">Ubah Status Tempahan</h2>
              <form phx-submit="update_status" class="space-y-3">
                <select name="status" phx-change="status_changed" class="w-full border rounded-md p-2 text-sm">
                  <option value="pending" selected={@edit_booking && @edit_booking.status == "pending"}>Menunggu</option>
                  <option value="approved" selected={@edit_booking && @edit_booking.status == "approved"}>Diluluskan</option>
                  <option value="rejected" selected={@edit_booking && @edit_booking.status == "rejected"}>Ditolak</option>
                  <option value="completed" selected={@edit_booking && @edit_booking.status == "completed"}>Selesai</option>
                  <option value="cancelled" selected={@edit_booking && @edit_booking.status == "cancelled"}>Dibatalkan</option>
                </select>

                <%= if @selected_status == "rejected" or (@edit_booking && @edit_booking.status == "rejected") do %>
                  <textarea name="reason" rows="3" class="w-full border rounded-md p-2 text-sm" placeholder="Nyatakan sebab penolakan..."><%= @edit_booking && (@edit_booking.rejection_reason || "") %></textarea>
                <% end %>

                <div class="flex justify-end gap-2">
                  <button type="submit" class="px-3 py-1 bg-blue-600 text-white rounded-md">Simpan</button>
                  <button type="button" phx-click="close_modal" class="px-3 py-1 border rounded-md">Batal</button>
                </div>
              </form>
            </.modal>

            <!-- Modal: Approve confirmation -->
            <.modal :if={@show_approve_modal} id="approve-equipment-modal" show on_cancel={JS.push("close_modal")}>
              <h2 class="text-lg font-semibold mb-3">Sahkan Tempahan</h2>

              <%= if @approve_booking do %>
                <p class="mb-2">
                  Sahkan tempahan
                  <b><%= @approve_booking.equipment.name %></b>
                  daripada
                  <b><%= User.display_name(@approve_booking.user) %></b>?
                </p>

                <ul class="text-sm text-gray-600 space-y-1 mb-4">
                  <li><b>Lokasi:</b> <%= @approve_booking.location %></li>
                  <li><b>Tarikh Guna:</b> <%= Calendar.strftime(@approve_booking.usage_at, "%d-%m-%Y %H:%M") %></li>
                  <li><b>Tarikh Pulang:</b> <%= Calendar.strftime(@approve_booking.return_at, "%d-%m-%Y %H:%M") %></li>
                  <li><b>Kuantiti:</b> <%= @approve_booking.requested_quantity %> unit</li>
                  <%= if @approve_booking.additional_notes do %>
                    <li><b>Catatan:</b> <%= @approve_booking.additional_notes %></li>
                  <% end %>
                </ul>
              <% end %>

              <div class="flex justify-end gap-2">
                <button type="button" phx-click="confirm_approve" class="px-3 py-1 bg-green-600 text-white rounded-md">Sahkan</button>
                <button type="button" phx-click="close_modal" class="px-3 py-1 border rounded-md">Batal</button>
              </div>
            </.modal>
          </section>
        </main>
      </div>
    </div>
    """
  end
end

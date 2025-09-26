defmodule SpatoWeb.MeetingRoomBookingLive.AdminIndex do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Bookings
  alias Spato.Accounts.User

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, "admin_meeting_rooms")
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
     |> load_meeting_room_bookings()
     |> assign(:stats, Bookings.get_meeting_room_booking_stats())}
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
     |> load_meeting_room_bookings()
     |> apply_action(socket.assigns.live_action, params)}
  end

  # --- EVENTS ---
  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    booking = Bookings.get_meeting_room_booking!(id)
    {:ok, _} = Bookings.approve_meeting_room_booking(booking)
    {:noreply,
     socket
     |> assign(:live_action, nil)
     |> load_meeting_room_bookings()
     |> put_flash(:info, "Tempahan telah diluluskan")}
  end

  @impl true
  def handle_event("reject", %{"id" => id}, socket) do
    booking = Bookings.get_meeting_room_booking!(id)
    {:ok, _} = Bookings.reject_meeting_room_booking(booking)
    {:noreply,
     socket
     |> assign(:live_action, nil)
     |> load_meeting_room_bookings()
     |> put_flash(:info, "Tempahan telah ditolak")}
  end

  @impl true
  def handle_event("open_reject_modal", %{"id" => id}, socket) do
    booking = Bookings.get_meeting_room_booking!(id)
    {:noreply,
     socket
     |> assign(:reject_booking, booking)
     |> assign(:show_reject_modal, true)}
  end

  @impl true
  def handle_event("submit_rejection", %{"reason" => reason}, socket) do
    {:ok, _} = Bookings.reject_meeting_room_booking(socket.assigns.reject_booking, reason)
    {:noreply,
     socket
     |> assign(:show_reject_modal, false)
     |> load_meeting_room_bookings()
     |> assign(:live_action, nil)}
  end

  @impl true
  def handle_event("status_changed", %{"status" => status}, socket) do
    {:noreply, socket |> assign(:selected_status, status) |> assign(:live_action, nil)}
  end

  @impl true
  def handle_event("open_edit_modal", %{"id" => id}, socket) do
    booking = Bookings.get_meeting_room_booking!(id)
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

    {:ok, _booking} = Bookings.update_meeting_room_booking(socket.assigns.edit_booking, update_params)

    {:noreply,
     socket
     |> assign(:show_edit_modal, false)
     |> load_meeting_room_bookings()
     |> assign(:selected_status, nil)
     |> assign(:live_action, nil)}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_reject_modal, false)
     |> assign(:show_edit_modal, false)
     |> assign(:live_action, nil)}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/admin/meeting_room_bookings?page=1&q=#{query}&status=#{socket.assigns.filter_status}&date=#{socket.assigns.filter_date}"
     )}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
      push_patch(socket,
        to: ~p"/admin/meeting_room_bookings?page=1&q=#{socket.assigns.search_query}&status=#{status}&date=#{socket.assigns.filter_date}") }
  end

  @impl true
  def handle_event("filter_date", %{"date" => date}, socket) do
    {:noreply,
      push_patch(socket,
        to: ~p"/admin/meeting_room_bookings?page=1&q=#{socket.assigns.search_query}&status=#{socket.assigns.filter_status}&date=#{date}") }
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/admin/meeting_room_bookings?page=#{page}&q=#{socket.assigns.search_query}&status=#{socket.assigns.filter_status}&date=#{socket.assigns.filter_date}"
     )}
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Butiran Tempahan Bilik Mesyuarat")
    |> assign(:meeting_room_booking, Bookings.get_meeting_room_booking!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Senarai Tempahan Bilik Mesyuarat")
    |> assign(:meeting_room_booking, nil)
  end

  # --- LOAD BOOKINGS ---
  defp load_meeting_room_bookings(socket) do
    params = %{
      "page" => socket.assigns.page,
      "search" => socket.assigns.search_query,
      "status" => socket.assigns.filter_status,
      "date" => socket.assigns.filter_date
    }

    data = Bookings.list_meeting_room_bookings_paginated(params)

    socket
    |> assign(:meeting_room_bookings_page, data.meeting_room_bookings_page)
    |> assign(:total_pages, data.total_pages)
    |> assign(:filtered_count, data.total)
    |> assign(:stats, Bookings.get_meeting_room_booking_stats())
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
            <!-- Page Title -->
            <h1 class="text-xl font-bold mb-1">Urus Tempahan Bilik Mesyuarat</h1>
            <p class="text-md text-gray-500 mb-4">Semak dan urus semua tempahan bilik mesyuarat dalam sistem</p>

            <!-- Stats Cards -->
            <div class="flex flex-wrap gap-4 mb-4">
              <%= for {label, value, color} <- [
                    {"Jumlah Tempahan", @stats.total, "text-gray-700"},
                    {"Menunggu Kelulusan", @stats.pending, "text-yellow-500"},
                    {"Diluluskan", @stats.approved, "text-green-500"},
                    {"Aktif", @stats.active, "text-blue-500"}
                  ] do %>
                <div class="flex-1 min-w-[180px] bg-white p-4 rounded-xl shadow-md flex flex-col justify-between h-30 transition-transform hover:scale-105">
                  <div>
                    <p class="text-sm text-gray-500"><%= label %></p>
                    <p class={"text-3xl font-bold mt-1 #{color}"}><%= value %></p>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Table Section -->
            <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
              <!-- Header -->
              <div class="flex items-center justify-between mb-4">
                <h2 class="text-lg font-semibold text-gray-900">Senarai Tempahan Bilik Mesyuarat</h2>
              </div>

              <!-- Search & Filters -->
              <div class="flex flex-wrap gap-2 mb-4">
                <!-- Search -->
                <form phx-change="search" class="flex-1 min-w-[200px]">
                  <input type="text" name="q" value={@search_query} placeholder="Cari tujuan, nama bilik..." class="w-full border rounded-md px-2 py-1 text-sm"/>
                </form>

                <!-- Date Filter -->
                <form phx-change="filter_date">
                  <input type="date" name="date" value={@filter_date} class="border rounded-md px-2 py-1 text-sm"/>
                </form>

                <!-- Status Filter -->
                <form phx-change="filter_status">
                  <select name="status" class="border rounded-md px-2 pr-8 py-1 text-sm">
                    <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                    <option value="pending" selected={@filter_status == "pending"}>Menunggu</option>
                    <option value="approved" selected={@filter_status == "approved"}>Diluluskan</option>
                    <option value="rejected" selected={@filter_status == "rejected"}>Ditolak</option>
                    <option value="completed" selected={@filter_status == "completed"}>Selesai</option>
                    <option value="cancelled" selected={@filter_status == "cancelled"}>Dibatalkan</option>
                  </select>
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
              <.table id="admin_meeting_room_bookings" rows={@meeting_room_bookings_page} row_click={fn booking -> JS.patch(
                ~p"/admin/meeting_room_bookings/#{booking.id}?action=show&page=#{@page}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"
              ) end}>
                <:col :let={booking} label="ID"><%= booking.id %></:col>
                <:col :let={booking} label="Bilik Mesyuarat">
                  <%= if booking.meeting_room do %>
                    <div class="flex flex-col">
                      <!-- Room Name -->
                      <div class="font-semibold text-gray-900">
                        <%= booking.meeting_room.name %>
                      </div>

                      <!-- Location -->
                      <div class="text-sm text-gray-500">
                        <%= booking.meeting_room.location %>
                      </div>

                      <!-- Capacity -->
                      <div class="mt-1">
                        <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">
                          Kapasiti: <%= booking.meeting_room.capacity %>
                        </span>
                      </div>
                    </div>
                  <% else %>
                    <span class="text-gray-400">—</span>
                  <% end %>
                </:col>
                <:col :let={booking} label="Dibuat Oleh">
                  <%= if booking.user do %>
                    <div class="flex flex-col">
                      <span class="font-medium text-gray-900">
                        <%= User.display_name(booking.user) %>
                      </span>
                      <%= if booking.user.user_profile && booking.user.user_profile.department do %>
                        <span class="text-sm text-gray-500">
                          <%= booking.user.user_profile.department.name %>
                        </span>
                      <% end %>
                    </div>
                  <% else %>
                    -
                  <% end %>
                </:col>
                <:col :let={booking} label="Tujuan">
                  <div class="flex flex-col">
                    <span class="font-medium text-gray-900"><%= booking.purpose %></span>
                    <span class="text-sm text-gray-500"><%= booking.notes %></span>
                  </div>
                </:col>
                <:col :let={booking} label="Peserta">
                  <div class="flex items-center gap-1">
                    <.icon name="hero-user" class="w-4 h-4 text-gray-500" />
                    <span><%= booking.participants %> / <%= booking.meeting_room.capacity %></span>
                  </div>
                </:col>
                <:col :let={booking} label="Masa Mula">
                  <div class="flex flex-col">
                    <span class="font-medium text-gray-900"><%= Calendar.strftime(booking.start_time, "%d-%m-%Y") %></span>
                    <span class="text-sm text-gray-500"><%= Calendar.strftime(booking.start_time, "%H:%M") %></span>
                  </div>
                </:col>

                <:col :let={booking} label="Masa Tamat">
                  <div class="flex flex-col">
                    <span class="font-medium text-gray-900"><%= Calendar.strftime(booking.end_time, "%d-%m-%Y") %></span>
                    <span class="text-sm text-gray-500"><%= Calendar.strftime(booking.end_time, "%H:%M") %></span>
                  </div>
                </:col>

                <:col :let={booking} label="Catatan Tambahan">{booking.notes}</:col>
                <:col :let={booking} label="Status">
                  <span class={"px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
                    case booking.status do
                      "pending" -> "bg-yellow-500"
                      "approved" -> "bg-green-500"
                      "rejected" -> "bg-red-500"
                      "completed" -> "bg-blue-500"
                      "cancelled" -> "bg-gray-400"
                      _ -> "bg-gray-400"
                    end
                  }>
                    <%= Spato.Bookings.MeetingRoomBooking.human_status(booking.status) %>
                  </span>
                </:col>

                <:action :let={booking}>
                  <%= case booking.status do %>
                    <% "pending" -> %>
                      <button
                        phx-click="approve"
                        phx-value-id={booking.id}
                        class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-green-600 hover:bg-green-700 text-white"
                        title="Luluskan"
                      >
                        <.icon name="hero-check" class="w-4 h-4" />
                      </button>

                      <button
                        phx-click="open_reject_modal"
                        phx-value-id={booking.id}
                        class="inline-flex items-center justify-center w-8 h-8 rounded-full bg-red-600 hover:bg-red-700 text-white ml-2"
                        title="Tolak"
                      >
                        <.icon name="hero-x-mark" class="w-4 h-4" />
                      </button>

                    <% "approved" -> %>
                      <button
                        phx-click="open_edit_modal"
                        phx-value-id={booking.id}
                        class="px-3 py-1 text-xs bg-blue-500 hover:bg-blue-600 text-white rounded-md"
                      >
                        Ubah Status
                      </button>

                    <% "rejected" -> %>
                      <%= if booking.rejection_reason do %>
                        <p class="text-xs text-red-500">Ditolak</p>
                      <% end %>

                    <% "completed" -> %>
                      <span class="text-sm text-blue-600">Selesai</span>
                    <% "cancelled" -> %>
                      <%= if booking.rejection_reason do %>
                        <p class="text-xs text-gray-500">Dibatalkan</p>
                      <% end %>
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
                    <.link
                      patch={~p"/admin/meeting_room_bookings?page=#{max(@page - 1, 1)}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                      class={"px-3 py-1 border rounded " <>
                        if @page == 1,
                          do: "bg-gray-200 text-gray-500 cursor-not-allowed",
                          else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Sebelumnya
                    </.link>
                  </div>

                  <!-- Page Numbers -->
                  <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
                    <%= for p <- 1..@total_pages do %>
                      <.link
                        patch={~p"/admin/meeting_room_bookings?page=#{p}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                        class={"px-3 py-1 border rounded " <>
                          if p == @page,
                            do: "bg-gray-700 text-white",
                            else: "bg-white text-gray-700 hover:bg-gray-100"}>
                        <%= p %>
                      </.link>
                    <% end %>
                  </div>

                  <!-- Next -->
                  <div class="flex-1 text-right">
                    <.link
                      patch={~p"/admin/meeting_room_bookings?page=#{min(@page + 1, @total_pages)}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                      class={"px-3 py-1 border rounded " <>
                        if @page == @total_pages,
                          do: "bg-gray-200 text-gray-500 cursor-not-allowed",
                          else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Seterusnya
                    </.link>
                  </div>
                </div>
              <% end %>
            </section>

            <!-- Modal: Show booking -->
            <.modal
              :if={@live_action == :show}
              id="admin-meeting-room-booking-show"
              show
              on_cancel={JS.patch(~p"/admin/meeting_room_bookings?page=#{@page}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}")}>
              <.live_component
                module={SpatoWeb.MeetingRoomBookingLive.AdminShowComponent}
                id={@meeting_room_booking.id}
                meeting_room_booking={@meeting_room_booking}
              />
            </.modal>

            <!-- Modal: Reject with reason -->
            <.modal :if={@show_reject_modal} id="reject-meeting-room-modal" show on_cancel={JS.push("close_modal")}>
              <h2 class="text-lg font-semibold mb-2">Sebab Penolakan</h2>
              <form phx-submit="submit_rejection" class="space-y-3">
                <textarea name="reason" rows="3" class="w-full border rounded-md p-2 text-sm" placeholder="Nyatakan sebab penolakan..."></textarea>
                <div class="flex justify-end gap-2">
                  <button type="button" phx-click="close_modal" class="px-3 py-1 border rounded-md">Batal</button>
                  <button type="submit" class="px-3 py-1 bg-red-600 text-white rounded-md">Tolak</button>
                </div>
              </form>
            </.modal>

            <!-- Modal: Edit status -->
            <.modal :if={@show_edit_modal} id="edit-meeting-room-modal" show on_cancel={JS.push("close_modal")}>
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
                  <button type="button" phx-click="close_modal" class="px-3 py-1 border rounded-md">Batal</button>
                  <button type="submit" class="px-3 py-1 bg-blue-600 text-white rounded-md">Simpan</button>
                </div>
              </form>
            </.modal>
          </section>
        </main>
      </div>
    </div>
    """
  end
end

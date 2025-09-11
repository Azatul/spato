defmodule SpatoWeb.MeetingRoomBookingLive.Index do
  use SpatoWeb, :live_view

  alias Spato.Bookings
  alias Spato.Bookings.MeetingRoomBooking

  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar


  @impl true
  def mount(_params, session, socket) do
  user = Spato.Accounts.get_user_by_session_token(session["user_token"])

  summary  = Bookings.booking_summary()


  {:ok,
    socket
    |> assign(:current_user, user)
    |> assign(:summary, summary)
    |> assign(:active_tab, "manage_meeting_rooms")
    |> assign(:sidebar_open, true)
    |> assign(:filter_status, "all")
    |> assign(:search_query, "")
    |> assign(:page, 1)
    |> load_bookings()}
end


  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Meeting room booking")
    |> assign(:meeting_room_booking, Bookings.get_meeting_room_booking!(id))
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Lihat Tempahan")
    |> assign(:meeting_room_booking, Bookings.get_meeting_room_booking!(id))
  end


  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Meeting room booking")
    |> assign(:meeting_room_booking, %MeetingRoomBooking{})
  end

  defp apply_action(socket, :index, params) do
    page   = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "q", "")
    status = Map.get(params, "status", "all")

    socket
    |> assign(:page_title, "Listing Meeting room bookings")
    |> assign(:meeting_room_booking, nil)
    |> assign(:page, page)
    |> assign(:search_query, search)
    |> assign(:filter_status, status)
    |> load_bookings()
  end

  defp load_bookings(socket) do
    params = %{
      "page" => socket.assigns.page,
      "search" => socket.assigns.search_query,
      "status" => socket.assigns.filter_status
    }

    data = Bookings.list_meeting_room_bookings_paginated(params)

    socket
    |> assign(:bookings_page, data.bookings_page)
    |> assign(:total_pages, data.total_pages)
    |> assign(:filtered_count, data.total)
  end

  @impl true
  def handle_info({SpatoWeb.MeetingRoomBookingLive.FormComponent, {:saved, _meeting_room_booking}}, socket) do
    {:noreply,
    socket
    |> load_bookings()
    |> assign(:summary, Bookings.booking_summary())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    meeting_room_booking = Bookings.get_meeting_room_booking!(id)
    {:ok, _} = Bookings.delete_meeting_room_booking(meeting_room_booking)

    {:noreply,
    socket
    |> load_bookings()
    |> assign(:summary, Bookings.booking_summary())}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket), do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 1)
     |> load_bookings()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/meeting_room_bookings?page=1&q=#{socket.assigns.search_query}&status=#{status}"
     )}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, String.to_integer(page))
     |> load_bookings()}
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
          <h1 class="text-xl font-bold mb-1">Tempah Bilik Mesyuarat</h1>
          <p class="text-md text-gray-500 mb-4">Semak dan urus semua menu katering dalam sistem</p>


      <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <!-- Total Booking -->
            <div
              class="p-6 bg-blue-100 rounded-xl shadow-md hover:shadow-xl transform hover:scale-105 transition-all duration-300"
            >
              <div class="flex items-center justify-between">
                <h3 class="text-sm font-medium text-blue-800">Aktiviti Tempahan Bilik</h3>
                <span class="text-blue-600">
                  <.icon name="hero-building-office" class="w-6 h-6"/>
                </span>
              </div>
              <p
                id="summary-total"
                phx-update="replace"
                class="text-3xl font-extrabold mt-2 transition-all duration-500 ease-out"
              >
                <%= @summary.total %>
              </p>
            </div>

            <!-- Pending -->
            <div
              class="p-6 bg-yellow-100 rounded-xl shadow-md hover:shadow-xl transform hover:scale-105 transition-all duration-300"
            >
              <div class="flex items-center justify-between">
                <h3 class="text-sm font-medium text-yellow-800">Menunggu Kelulusan</h3>
                <span class="text-yellow-600">
                  <.icon name="hero-clock" class="w-6 h-6"/>
                </span>
              </div>
              <p
                id="summary-pending"
                phx-update="replace"
                class="text-3xl font-extrabold mt-2 transition-all duration-500 ease-out"
              >
                <%= @summary.pending %>
              </p>
            </div>

            <!-- This Month -->
            <div
              class="p-6 bg-green-100 rounded-xl shadow-md hover:shadow-xl transform hover:scale-105 transition-all duration-300"
            >
              <div class="flex items-center justify-between">
                <h3 class="text-sm font-medium text-green-800">Tempahan Bulan Ini</h3>
                <span class="text-green-600">
                  <.icon name="hero-calendar-days" class="w-6 h-6"/>
                </span>
              </div>
              <p
                id="summary-month"
                phx-update="replace"
                class="text-3xl font-extrabold mt-2 transition-all duration-500 ease-out"
              >
                <%= @summary.this_month %>
              </p>
            </div>
          </div>

          <!-- Button tempah bilik baru -->
            <div class="flex justify-end mb-4">
              <.link
                patch={~p"/meeting_room_bookings/new"}
                class="px-4 py-2 bg-blue-600 text-white rounded-lg shadow hover:bg-blue-700 transition"
              >
                + Tempah Bilik Baru
              </.link>
            </div>

          <!-- Filters & Search -->
          <div class="bg-white p-4 md:p-6 rounded-xl shadow-md mb-4">
            <div class="flex flex-wrap gap-2 items-center">
              <form phx-change="search" class="flex-1 min-w-[200px]">
                <input type="text" name="q" value={@search_query} placeholder="Cari tujuan, nota atau pola berulang..." class="w-full border rounded-md px-2 py-1 text-sm"/>
              </form>

              <form phx-change="filter_status">
                <select name="status" class="border rounded-md px-2 pr-8 py-1 text-sm">
                  <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                  <option value="pending" selected={@filter_status == "pending"}>Dalam Proses</option>
                  <option value="approved" selected={@filter_status == "approved"}>Diterima</option>
                  <option value="rejected" selected={@filter_status == "rejected"}>Ditolak</option>
                </select>
              </form>
            </div>
          </div>

        <!-- Count message -->
        <div class="mb-2 text-sm text-gray-600">
          <%= if @filtered_count == 0 do %>
            Tiada tempahan ditemui
          <% else %>
            <%= @filtered_count %> tempahan ditemui
          <% end %>
        </div>

        <.table
          id="meeting_room_bookings"
          rows={@bookings_page}
          row_click={fn meeting_room_booking ->
            JS.patch(~p"/meeting_room_bookings/#{meeting_room_booking.id}/show")
          end}
        >

      >
        <:col :let={meeting_room_booking} label="Booking ID">
        <%= meeting_room_booking.id %>
        </:col>
        <:col :let={meeting_room_booking} label="Purpose">{meeting_room_booking.purpose}</:col>
        <:col :let={meeting_room_booking} label="Participants">{meeting_room_booking.participants}</:col>
        <:col :let={meeting_room_booking} label="Start time">{meeting_room_booking.start_time}</:col>
        <:col :let={meeting_room_booking} label="End time">{meeting_room_booking.end_time}</:col>
        <:col :let={meeting_room_booking} label="Recurrence pattern">{meeting_room_booking.recurrence_pattern}</:col>
        <:col :let={meeting_room_booking} label="Status">
        <%= case meeting_room_booking.status do %>
          <% "approved" -> %> Diterima
          <% "pending" -> %> Dalam Proses
          <% "rejected" -> %> Ditolak
          <% _ -> %> -
        <% end %>
        </:col>

        <:col :let={meeting_room_booking} label="Notes">{meeting_room_booking.notes}</:col>
        <:action :let={meeting_room_booking}>
          <div class="sr-only">
            <.link navigate={~p"/meeting_room_bookings/#{meeting_room_booking}"}>Show</.link>
          </div>
          <.link patch={~p"/meeting_room_bookings/#{meeting_room_booking}/edit"}>Edit</.link>
        </:action>
        <:action :let={meeting_room_booking}>
          <.link
            phx-click={JS.push("delete", value: %{id: meeting_room_booking.id}) |> hide("##{meeting_room_booking.id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>

      <!-- Pagination -->
      <%= if @filtered_count > 0 do %>
        <div class="relative flex items-center mt-4">
          <div class="flex-1">
            <.link
              patch={~p"/meeting_room_bookings?page=#{max(@page - 1, 1)}&q=#{@search_query}&status=#{@filter_status}"}
              class={"px-3 py-1 border rounded #{if @page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
            >
              Sebelumnya
            </.link>
          </div>

          <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
            <%= for p <- 1..@total_pages do %>
              <.link
                patch={~p"/meeting_room_bookings?page=#{p}&q=#{@search_query}&status=#{@filter_status}"}
                class={"px-3 py-1 border rounded #{if p == @page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
              >
                <%= p %>
              </.link>
            <% end %>
          </div>

          <div class="flex-1 text-right">
            <.link
              patch={~p"/meeting_room_bookings?page=#{min(@page + 1, @total_pages)}&q=#{@search_query}&status=#{@filter_status}"}
              class={"px-3 py-1 border rounded #{if @page == @total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
            >
              Seterusnya
            </.link>
          </div>
        </div>
      <% end %>

      <.modal :if={@live_action in [:new, :edit, :show]}
        id="meeting_room_booking-modal"
        show
        on_cancel={JS.patch(~p"/meeting_room_bookings")}>

            <%= if @live_action == :show do %>
              <!-- View details modal -->
              <div class="p-4">
                <h2 class="text-lg font-bold mb-2">Maklumat Tempahan</h2>
                <p><b>Purpose:</b> <%= @meeting_room_booking.purpose %></p>
                <p><b>Participants:</b> <%= @meeting_room_booking.participants %></p>
                <p><b>Start:</b> <%= @meeting_room_booking.start_time %></p>
                <p><b>End:</b> <%= @meeting_room_booking.end_time %></p>
                <p><b>Status:</b> <%= @meeting_room_booking.status %></p>
                <p><b>Notes:</b> <%= @meeting_room_booking.notes %></p>
              </div>
            <% else %>
              <!-- Biasa untuk edit/new -->
              <.live_component
                module={SpatoWeb.MeetingRoomBookingLive.FormComponent}
                id={@meeting_room_booking.id || :new}
                title={@page_title}
                action={@live_action}
                meeting_room_booking={@meeting_room_booking}
                patch={~p"/meeting_room_bookings"}
              />
            <% end %>
          </.modal>
        </section>
      </main>
      </div>
      </div>
    """
  end
end

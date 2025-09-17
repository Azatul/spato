defmodule SpatoWeb.MeetingRoomBookingLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar
  alias Spato.Bookings
  alias Spato.Bookings.MeetingRoomBooking

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    bookings = Bookings.list_meeting_room_bookings()
    stats = compute_stats(bookings)

    {:ok,
     socket
     |> assign(:active_tab, "meeting_rooms")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:filter_status, "all")
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:meeting_room_booking, nil)
     |> assign(:meeting_room_bookings, bookings)
     |> assign(:meeting_room_bookings_page, bookings)
   |> assign(:total_pages, 1)
     |> assign(:stats, stats)}
  end
  defp compute_stats(bookings) do
    %{
      total: Enum.count(bookings),
      pending: Enum.count(bookings, &(&1.status == "pending")),
      approved: Enum.count(bookings, &(&1.status == "approved")),
      completed: Enum.count(bookings, &(&1.status == "completed"))
    }
  end


  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  @impl true
def handle_event("search", %{"q" => query}, socket) do
  filtered = Bookings.search_meeting_room_bookings(socket.assigns.current_user, query)
  stats = compute_stats(filtered)

  {:noreply,
   socket
   |> assign(:search_query, query)
   |> assign(:meeting_room_bookings, filtered)
   |> load_meeting_room_bookings()}
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
   |> load_meeting_room_bookings()}
end

@impl true
def handle_event("delete", %{"id" => id}, socket) do
  booking = Bookings.get_meeting_room_booking!(id)
  {:ok, _} = Bookings.delete_meeting_room_booking(booking)

  bookings = Enum.reject(socket.assigns.meeting_room_bookings, fn b -> b.id == booking.id end)
  stats = compute_stats(bookings)

  {:noreply,
   socket
   |> assign(:meeting_room_bookings, bookings)
   |> assign(:stats, stats)}
end


  @impl true
  def handle_params(params, _url, socket) do
    action = socket.assigns.live_action
    {:noreply, apply_action(socket, action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Senarai Tempahan Bilik Mesyuarat")
    |> assign(:meeting_room_booking, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Tempahan Bilik Baru")
    |> assign(:meeting_room_booking, %MeetingRoomBooking{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    booking = Bookings.get_meeting_room_booking!(id)

    socket
    |> assign(:page_title, "Kemaskini Tempahan Bilik")
    |> assign(:meeting_room_booking, booking)
  end

# --- LOAD BOOKINGS PAGINATED ---
    defp load_meeting_room_bookings(socket) do
      params = %{
        "page" => socket.assigns.page,
        "search" => socket.assigns.search_query,
        "status" => socket.assigns.filter_status
      }

      data = Bookings.list_meeting_room_bookings_paginated(params, socket.assigns.current_user)

      socket
      |> assign(:meeting_room_bookings_page, data.bookings_page)
      |> assign(:total_pages, data.total_pages)
      |> assign(:filtered_count, data.total)
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
          <section class="mb-4 flex justify-between items-center">
            <h1 class="text-xl font-bold"><%= @page_title %></h1>
            <.link patch={~p"/meeting_room_bookings/new"}>
              <.button>Tempah Bilik Baru</.button>
            </.link>
          </section>

          <!-- Summary Cards -->
          <section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
            <%= for {label, value, color} <- [
                  {"Jumlah Tempahan", @stats.total, "text-gray-700"},
                  {"Menunggu", @stats.pending, "text-yellow-500"},
                  {"Diluluskan", @stats.approved, "text-green-500"},
                  {"Selesai", @stats.completed, "text-blue-500"}
                ] do %>

              <div class="bg-white p-4 rounded-xl shadow-md flex flex-col justify-between h-30 transition-transform hover:scale-105">
                <div>
                  <p class="text-sm text-gray-500"><%= label %></p>
                  <p class={"text-3xl font-bold mt-1 #{color}"}><%= value %></p>
                </div>
              </div>
            <% end %>
          </section>

             <div class="bg-white p-4 rounded-xl shadow-md">
              <!-- Search & Status Filter -->
              <div class="flex gap-2 mb-4 flex-wrap items-end">
                <form phx-change="search" class="flex-1 min-w-[200px]">
                  <input type="text" name="q" value={@search_query} placeholder="Cari..." class="w-full border rounded-md px-2 py-1 text-sm"/>
                </form>
                <form phx-change="filter_status">
                  <select name="status" class="border rounded-md px-2 py-1 text-sm">
                    <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                    <option value="pending" selected={@filter_status == "pending"}>Menunggu</option>
                    <option value="approved" selected={@filter_status == "approved"}>Diluluskan</option>
                    <option value="completed" selected={@filter_status == "completed"}>Selesai</option>
                  </select>
                </form>
              </div>

              <.table id="meeting_room_bookings" rows={@meeting_room_bookings_page}>
                <:col :let={booking} label="ID"><%= booking.id %></:col>
                <:col :let={booking} label="Nama Bilik"><%= if booking.meeting_room, do: booking.meeting_room.name, else: "-" %></:col>
                <:col :let={booking} label="Ditempah Oleh"><%= booking.user.name %></:col>
                <:col :let={booking} label="Masa Mula"><%= Calendar.strftime(booking.start_time, "%d-%m-%Y %H:%M") %></:col>
                <:col :let={booking} label="Masa Tamat"><%= Calendar.strftime(booking.end_time, "%d-%m-%Y %H:%M") %></:col>
                <:col :let={booking} label="Tujuan"><%= booking.purpose %></:col>
                <:col :let={booking} label="Peserta"><%= booking.participants %></:col>
                <:action :let={booking}>
                  <.link patch={~p"/meeting_room_bookings/#{booking.id}/edit"} class="text-blue-600 hover:underline">Edit</.link>
                  <.link phx-click="delete" phx-value-id={booking.id} data-confirm="Are you sure?" class="text-red-600 hover:underline">Delete</.link>
                </:action>
              </.table>

              <!-- Pagination -->
              <div class="flex justify-between mt-4">
                <.link
                  patch={~p"/meeting_room_bookings?page=#{max(@page - 1, 1)}&q=#{@search_query}&status=#{@filter_status}"}
                  class={"px-3 py-1 border rounded #{if @page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}>
                  Sebelumnya
                </.link>

                <.link
                  patch={~p"/meeting_room_bookings?page=#{min(@page + 1, @total_pages)}&q=#{@search_query}&status=#{@filter_status}"}
                  class={"px-3 py-1 border rounded #{if @page == @total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}>
                  Seterusnya
                </.link>
              </div>
            </div>

          <!-- Modal for new/edit -->
          <.modal :if={@live_action in [:new, :edit]} id="meeting_room_booking-modal" show on_cancel={JS.patch(~p"/meeting_room_bookings")}>
            <.live_component
              module={SpatoWeb.MeetingRoomBookingLive.FormComponent}
              id={@meeting_room_booking.id || :new}
              title={@page_title}
              action={@live_action}
              meeting_room_booking={@meeting_room_booking}
              patch={~p"/meeting_room_bookings"}
            />
          </.modal>
        </main>
      </div>
    </div>
    """
  end
end

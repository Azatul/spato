defmodule SpatoWeb.MeetingRoomBookingLive.AdminIndex do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Bookings

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, session, socket) do
    admin = Spato.Accounts.get_user_by_session_token(session["user_token"])

    bookings = Bookings.list_meeting_room_bookings()
    total = length(bookings)
    pending = Enum.count(bookings, &(&1.status == "pending"))
    approved = Enum.count(bookings, &(&1.status == "approved"))
    active_rooms = Spato.Assets.list_meeting_rooms() |> Enum.count(&(&1.status == "tersedia"))

    {:ok,
     socket
     |> assign(:current_admin, admin)
     |> assign(:current_user, admin) # supaya sidebar & headbar dapat user
     |> assign(:page_title, "Kelulusan Tempahan Bilik")
     |> assign(:active_tab, "admin_bookings") # kau boleh define tab ikut sidebar
     |> assign(:sidebar_open, true)
     |> assign(:summary, %{
      total: total,
      pending: pending,
      approved: approved,
      active_rooms: active_rooms
      })
     |> assign(:bookings, Bookings.list_meeting_room_bookings())}
  end

  @impl true
  def handle_event("approve", %{"id" => id}, socket) do
    booking = Bookings.get_meeting_room_booking!(id)
    {:ok, _} = Bookings.approve_meeting_room_booking(booking)

    {:noreply,
    socket
    |> assign(:bookings, Bookings.list_meeting_room_bookings())
    |> update_summary()}
  end

  @impl true
  def handle_event("reject", %{"id" => id}, socket) do
    booking = Bookings.get_meeting_room_booking!(id)
    {:ok, _} = Bookings.reject_meeting_room_booking(booking)

    {:noreply,
    socket
    |> assign(:bookings, Bookings.list_meeting_room_bookings())
    |> update_summary()}
  end


  @impl true
  def handle_event("toggle_sidebar", _, socket),
    do: {:noreply, update(socket, :sidebar_open, &(!&1))}

    defp summary_card(assigns) do
      ~H"""
      <div class="bg-white shadow rounded-lg p-6 flex flex-col items-center justify-center
                  transform transition duration-500 hover:scale-105 hover:shadow-xl">
        <div class="text-3xl font-extrabold text-blue-600 animate-fade-in"><%= @count %></div>
        <div class="text-sm text-gray-500 mt-2"><%= @label %></div>
      </div>
      """
    end

    defp update_summary(socket) do
      bookings = Bookings.list_meeting_room_bookings()
      total = length(bookings)
      pending = Enum.count(bookings, &(&1.status == "pending"))
      approved = Enum.count(bookings, &(&1.status == "approved"))
      active_rooms = Spato.Assets.list_meeting_rooms() |> Enum.count(&(&1.status == "tersedia"))

      assign(socket, :summary, %{
        total: total,
        pending: pending,
        approved: approved,
        active_rooms: active_rooms
      })
    end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden">
      <!-- Sidebar -->
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" />

      <!-- Main Content -->
      <div class="flex flex-col flex-1">
        <!-- Headbar -->
        <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

        <!-- Page Content -->
        <main class="flex-1 overflow-y-auto pt-20 p-6 transition-all duration-300 bg-gray-100">
          <h1 class="text-xl font-bold mb-4">Kelulusan Tempahan Bilik (Admin)</h1>

        <!-- Summary Cards -->
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <.summary_card count={@summary.total} label="Jumlah Tempahan" />
            <.summary_card count={@summary.pending} label="Menunggu Kelulusan" />
            <.summary_card count={@summary.approved} label="Diluluskan" />
            <.summary_card count={@summary.active_rooms} label="Bilik Aktif" />
          </div>
            <.table id="admin-bookings" rows={@bookings}>
              <:col :let={b} label="ID Tempahan"><%= b.id %></:col>
              <:col :let={b} label="Bilik">
                <%= if b.room, do: b.room.name, else: "-" %>
              </:col>
              <:col :let={b} label="Ditempah Oleh">
                <%= if b.user, do: b.user.name, else: "-" %>
              </:col>
              <:col :let={b} label="Tarikh & Masa">
                <%= Calendar.strftime(b.start_time, "%Y-%m-%d %H:%M") %> –
                <%= Calendar.strftime(b.end_time, "%H:%M") %>
              </:col>
              <:col :let={b} label="Tujuan"><%= b.purpose %></:col>
              <:col :let={b} label="Peserta"><%= b.participants %></:col>

              <:col :let={b} label="Status">
                <%= case b.status do %>
                  <% "pending" -> %>
                    <div class="flex gap-2">
                      <.link phx-click="approve" phx-value-id={b.id}
                            class="px-3 py-1 bg-green-600 text-white rounded hover:bg-green-700 transition">
                        Terima
                      </.link>
                      <.link phx-click="reject" phx-value-id={b.id}
                            class="px-3 py-1 bg-red-600 text-white rounded hover:bg-red-700 transition">
                        Tolak
                      </.link>
                    </div>
                  <% "approved" -> %>
                    <span class="px-3 py-1 rounded bg-green-100 text-green-700 font-semibold">Diterima</span>
                  <% "rejected" -> %>
                    <span class="px-3 py-1 rounded bg-red-100 text-red-700 font-semibold">Ditolak</span>
                  <% _ -> %>
                    <span class="italic text-gray-500"><%= b.status %></span>
                <% end %>
              </:col>
            </.table>
        </main>
      </div>
    </div>
    """
  end
end

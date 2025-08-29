defmodule SpatoWeb.MeetingRoomLive.Index do
  use SpatoWeb, :live_view

  alias Spato.Assets
  alias Spato.Assets.MeetingRoom

  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do

    summary_counts = %{
      total: Assets.count_meeting_rooms(),
      tersedia: Assets.count_meeting_rooms_by_status("Tersedia"),
      maintenance: Assets.count_meeting_rooms_by_status("Penyelenggaraan"),
      booked: Assets.count_meeting_rooms_by_status("Digunakan")
    }

    {:ok,
     socket
     |> assign(:page_title, "Senarai Bilik Mesyuarat")
     |> assign(:active_tab, "manage_meeting_rooms")
     |> assign(:sidebar_open, true)
     |> assign(:summary_counts, summary_counts)
     |> assign(:current_user, socket.assigns.current_user)
     |> stream(:meeting_rooms, Assets.list_meeting_rooms())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Meeting room")
    |> assign(:meeting_room, Assets.get_meeting_room!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Meeting room")
    |> assign(:meeting_room, %MeetingRoom{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Meeting rooms")
    |> assign(:meeting_room, nil)
  end

  @impl true
  def handle_info({SpatoWeb.MeetingRoomLive.FormComponent, {:saved, meeting_room}}, socket) do
    {:noreply, stream_insert(socket, :meeting_rooms, meeting_room)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    meeting_room = Assets.get_meeting_room!(id)
    {:ok, _} = Assets.delete_meeting_room(meeting_room)

    {:noreply, stream_delete(socket, :meeting_rooms, meeting_room)}
  end

  #sidebar
  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urus Bilik Mesyuarat</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
      body { font-family: 'Inter', sans-serif; }
    </style>

    <div class="flex h-screen overflow-hidden">
      <!-- Sidebar -->
      <.sidebar
        active_tab={@active_tab}
        current_user={@current_user}
        open={@sidebar_open}
        toggle_event="toggle_sidebar"
      />

      <!-- Headbar -->
      <.headbar
        current_user={@current_user}
        open={@sidebar_open}
        toggle_event="toggle_sidebar"
        title={@page_title}
      />

      <!-- Main content -->
      <div class="flex-1 flex flex-col p-6 overflow-y-auto">
        <!-- Header -->
        <.header>
          Senarai Bilik Mesyuarat
          <:actions>
            <.link patch={~p"/admin/meeting_rooms/new"}>
              <.button>+ Bilik Baru</.button>
            </.link>
          </:actions>
        </.header>

        <!-- Summary Cards -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8 mt-4">
          <div class="bg-white shadow-md rounded-lg p-6">
            <p class="text-gray-500 text-sm">Jumlah Bilik Mesyuarat</p>
            <p class="text-2xl font-bold text-gray-800"><%= @summary_counts.total %></p>
          </div>
          <div class="bg-white shadow-md rounded-lg p-6">
            <p class="text-gray-500 text-sm">Bilik Tersedia</p>
            <p class="text-2xl font-bold text-green-600"><%= @summary_counts.tersedia %></p>
          </div>
          <div class="bg-white shadow-md rounded-lg p-6">
            <p class="text-gray-500 text-sm">Dalam Penyelenggaraan</p>
            <p class="text-2xl font-bold text-yellow-600"><%= @summary_counts.maintenance %></p>
          </div>
          <div class="bg-white shadow-md rounded-lg p-6">
            <p class="text-gray-500 text-sm">Bilik Aktif</p>
            <p class="text-2xl font-bold text-red-600"><%= @summary_counts.booked %></p>
          </div>
        </div>

        <!-- Table -->
        <div class="overflow-x-auto bg-white shadow rounded-xl">
          <table class="min-w-full border-collapse">
            <thead>
              <tr class="bg-gray-200 text-center text-sm font-semibold text-gray-700">
                <th class="px-4 py-3 border-b">ID Bilik</th>
                <th class="px-4 py-3 border-b">Nama & Lokasi</th>
                <th class="px-4 py-3 border-b">Kapasiti</th>
                <th class="px-4 py-3 border-b">Fasiliti Tersedia</th>
                <th class="px-4 py-3 border-b">Ditambah Oleh</th>
                <th class="px-4 py-3 border-b">Tarikh & Masa Dikemaskini</th>
                <th class="px-4 py-3 border-b">Status</th>
                <th class="px-4 py-3 border-b">Tindakan</th>
              </tr>
            </thead>
            <tbody id="meeting_rooms" phx-update="stream">
              <%= for {dom_id, room} <- @streams.meeting_rooms do %>
                <tr id={dom_id} class="hover:bg-gray-50 text-sm">
                  <td class="px-4 py-3 border-b text-center font-medium"><%= room.id %></td>
                  <td class="px-4 py-3 text-center border-b">
                    <div class="font-semibold"><%= room.name %></div>
                    <div class="text-gray-500 text-xs"><%= room.location %></div>
                  </td>
                  <td class="px-4 py-3 text-center border-b"><%= room.capacity %> orang</td>
                  <td class="px-4 py-3 text-center border-b"><%= room.available_facility %></td>
                  <td class="px-4 py-3 text-center border-b">Pengguna ID: <%= room.created_by_user_id %></td>
                  <td class="px-4 py-3 border-b text-xs text-gray-500 text-center">
                    <%= Calendar.strftime(room.updated_at, "%d/%m/%Y %H:%M") %>
                  </td>
                  <td class="px-4 py-3 border-b text-center">
                    <span class={
                      "px-2 py-1 text-xs rounded-full " <>
                      case room.status do
                        "Tersedia" -> "bg-green-100 text-green-700"
                        "Dalam Penyelenggaraan" -> "bg-yellow-100 text-yellow-700"
                        _ -> "bg-gray-100 text-gray-600"
                      end
                    }>
                      <%= room.status %>
                    </span>
                  </td>
                  <td class="px-4 py-3 border-b text-center space-x-2">
                    <.link patch={~p"/admin/meeting_rooms/#{room.id}/edit"} class="text-blue-600 hover:underline">
                      Edit
                    </.link>
                    <.link
                      phx-click={JS.push("delete", value: %{id: room.id}) |> hide("##{dom_id}")}
                      data-confirm="Are you sure?"
                      class="text-red-600 hover:underline"
                    >
                      Delete
                    </.link>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end
end

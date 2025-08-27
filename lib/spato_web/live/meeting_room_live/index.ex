defmodule SpatoWeb.MeetingRoomLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar

  alias Spato.Assets
  alias Spato.Assets.MeetingRoom

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @page_size 10

  @impl true
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:page_title, "Listing Meeting rooms")
   |> assign(:active_tab, "meeting_rooms")
   |> assign(:sidebar_open, true)
   |> assign(:all_rooms, [])
   |> assign(:page, 1)
   |> assign(:page_size, @page_size)
   |> assign(:total_count, 0)
   |> assign(:keyword, "")
   |> assign(:filter_status, "")
   |> assign(:edit_modal_open, false)
   |> assign(:modal_open, false)
   |> assign(:edit_room, nil)
   |> assign(:edit_room_changeset, nil)
   |> assign(:new_room_changeset, to_form(Assets.change_meeting_room(%MeetingRoom{})))}
end


  # Sidebar toggle
  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  # Search
 # Search
@impl true
def handle_event("search", %{"keyword" => keyword}, socket) do
  {:noreply,
   push_patch(socket,
     to:
       ~p"/meeting_rooms?page=1&status=#{socket.assigns.filter_status}&keyword=#{keyword}"
   )}
end


  # Filter
  # Filter
@impl true
def handle_event("filter", %{"status" => status}, socket) do
  {:noreply,
   push_patch(socket,
     to:
       ~p"/meeting_rooms?page=1&status=#{status}&keyword=#{socket.assigns.keyword}"
   )}
end
def handle_event("ignore", _, socket), do: {:noreply, socket}


  # Pagination


  # Modal tambah bilik
  @impl true
  def handle_event("open_modal", _, socket), do: {:noreply, assign(socket, :modal_open, true)}
  def handle_event("close_modal", _, socket), do: {:noreply, assign(socket, :modal_open, false)}

  # Save new room
  @impl true
  def handle_event("save_room", %{"meeting_room" => room_params}, socket) do
    case Assets.create_meeting_room(room_params) do
      {:ok, room} ->
        {:noreply,
         socket
         |> stream_insert(:meeting_rooms, room)
         |> assign(:all_rooms, [room | socket.assigns.all_rooms])
         |> assign(:modal_open, false)
         |> assign(:new_room_changeset, to_form(Assets.change_meeting_room(%MeetingRoom{})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :new_room_changeset, to_form(changeset))}
    end
  end

  # Modal edit
  @impl true
  def handle_event("edit_room", %{"id" => id}, socket) do
    room = Assets.get_meeting_room!(id)

    {:noreply,
     socket
     |> assign(:edit_room, room)
     |> assign(:edit_room_changeset, to_form(Assets.change_meeting_room(room)))
     |> assign(:edit_modal_open, true)}
  end

  def handle_event("close_edit_modal", _, socket), do: {:noreply, assign(socket, :edit_modal_open, false)}

  @impl true
  def handle_event("update_room", %{"meeting_room" => room_params}, socket) do
    case Assets.update_meeting_room(socket.assigns.edit_room, room_params) do
      {:ok, room} ->
        {:noreply,
         socket
         |> put_flash(:info, "Bilik berjaya dikemaskini")
         |> stream_insert(:meeting_rooms, room)
         |> assign(:edit_modal_open, false)
         |> assign(:edit_room, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :edit_room_changeset, to_form(changeset))}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    status = Map.get(params, "status", "")
    keyword = Map.get(params, "keyword", socket.assigns.keyword || "")

    rooms = Assets.list_meeting_rooms_filtered(status, keyword, page, socket.assigns.page_size)
    total_count = Assets.count_meeting_rooms_filtered(status, keyword)

    # Kira summary guna semua bilik (tanpa pagination)
  all_for_summary = Assets.list_meeting_rooms_filtered(status, keyword, 1, 100_000)

  summary_counts = %{
    total: length(all_for_summary),
    tersedia: Enum.count(all_for_summary, &(&1.status == "Tersedia")),
    maintenance: Enum.count(all_for_summary, &(&1.status == "Dalam Penyelenggaraan")),
    booked: Enum.count(all_for_summary, &(&1.status == "booked"))
  }
    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:filter_status, status)
     |> assign(:keyword, keyword)
     |> assign(:all_rooms, rooms)
     |> assign(:total_count, total_count)
     |> assign(:summary_counts, summary_counts)
     |> stream(:meeting_rooms, rooms, reset: true)}
  end


  @impl true
  def render(assigns) do
    ~H"""
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Urus Bilik Mesyuarat</title>
    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- Font Awesome CDN for icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <!-- Google Font - Inter -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
    <!-- Custom CSS (optional, for specific overrides) -->
    <style>
        body {
            font-family: 'Inter', sans-serif;
        }
        /* Custom styles for the status badge as seen in the image */
        .bg-yellow-100-custom {
          background-color: #fef9c3;
        }

        .text-yellow-800-custom {
          color: #92400e;
        }

        .bg-green-100-custom {
          background-color: #dcfce7;
        }

        .text-green-800-custom {
          color: #166534;
        }
    </style>
    <div class="flex w-screen h-screen bg-gray-50 font-sans overflow-hidden">
      <!-- Sidebar -->
      <.sidebar
        active_tab={@active_tab}
        current_user={@current_user}
        open={@sidebar_open}
        toggle_event="toggle_sidebar"
      />

      <!-- Main Content -->
      <main class="flex-1 p-8 overflow-y-auto">
        <!-- Header -->
        <div class="flex justify-between items-center mb-8">
          <h1 class="text-3xl font-extrabold text-gray-900 tracking-tight">
            Senarai Bilik Mesyuarat
          </h1>
          <button
            class="inline-flex items-center px-5 py-2.5 rounded-xl bg-blue-600 text-white font-medium shadow hover:bg-blue-700 transition"
            phx-click={JS.push("open_modal")}
          >
            <.icon name="hero-plus-circle" class="w-5 h-5 mr-2" /> Tambah Bilik
          </button>
        </div>

       <!-- Summary Cards -->
<div class="grid grid-cols-4 gap-6 mb-8">
  <div class="bg-white shadow-md rounded-lg p-6 text-lg">
    <p class="text-gray-500 text-sm">Jumlah Bilik Mesyuarat Berdaftar</p>
    <p class="text-2xl font-bold text-gray-800"><%= @summary_counts.total %></p>
  </div>

  <div class="bg-white shadow-md rounded-lg p-6 text-lg">
    <p class="text-gray-500 text-sm">Bilik Mesyuarat Tersedia</p>
    <p class="text-2xl font-bold text-green-600"><%= @summary_counts.tersedia %></p>
  </div>

  <div class="bg-white shadow-md rounded-lg p-6 text-lg">
    <p class="text-gray-500 text-sm">Dalam Penyelenggaraan</p>
    <p class="text-2xl font-bold text-green-600"><%= @summary_counts.maintenance %></p>
  </div>

  <div class="bg-white shadow-md rounded-lg p-6 text-lg">
    <p class="text-gray-500 text-sm">Bilik Mesyuarat Aktif</p>
    <p class="text-2xl font-bold text-red-600"><%= @summary_counts.booked %></p>
  </div>
</div>


      <form phx-change="search" class="flex items-center justify-between mb-4 space-x-4">
  <input
    type="text"
    name="keyword"
    value={@keyword || ""}
    placeholder="Cari bilik..."
    phx-debounce="300"
    class="w-1/2 px-3 py-2 border rounded-lg"
  />

  <select
    name="status"
    phx-change="filter"
    class="px-3 py-2 border rounded-lg"
  >
    <option value="">Semua Status</option>
    <option value="available" selected={@filter_status == "available"}>Tersedia</option>
    <option value="maintenance" selected={@filter_status == "maintenance"}>Dalam Penyelenggaraan</option>
  </select>
</form>



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
        <th class="px-4 py-3 border-b text-center">
          Tarikh & Masa<br>Dikemaskini
        </th>
        <th class="px-4 py-3 border-b">Status</th>
        <th class="px-4 py-3 border-b">Tindakan</th>
      </tr>
    </thead>
    <tbody id="meeting_rooms" phx-update="stream">
      <%= for {dom_id, room} <- @streams.meeting_rooms do %>
        <tr id={dom_id} class="hover:bg-gray-50 text-sm">
          <!-- ID Bilik -->
          <td class="px-4 py-3 border-b text-center font-medium"><%= room.id %></td>

          <!-- Nama & Lokasi -->
          <td class="px-4 py-3 text-center border-b">
            <div class="font-semibold"><%= room.name %></div>
            <div class="text-gray-500 text-xs"><%= room.location %></div>
          </td>

          <!-- Kapasiti -->
          <td class="px-4 py-3 text-center border-b"><%= room.capacity %> orang</td>

          <!-- Fasiliti -->
          <td class="px-4 py-3 text-center border-b"><%= room.available_facility %></td>

          <!-- Ditambah Oleh -->
          <td class="px-4 py-3 text-center border-b">
            Pengguna ID: <%= room.created_by_user_id %>
            <% # kalau ada preload: <%= room.user.name %> %>
          </td>

         <!-- Tarikh & Masa -->
        <td class="px-4 py-3 border-b text-xs text-gray-500 text-center">
        <div class="flex items-center justify-center h-full">
          <%= room.updated_at |> Calendar.strftime("%d/%m/%Y %H:%M") %>
          </div>
        </td>


        <!-- Status -->
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

        <!-- Tindakan -->
        <td class="px-4 py-3 border-b text-center">
          <button
            class="text-blue-600 hover:underline mr-3"
            phx-click="edit_room"
            phx-value-id={room.id}
          >
            Edit
          </button>
        </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>

<!-- Pagination buttons -->
<div class="flex justify-between mt-4 items-center">
  <!-- Prev button -->
  <.link
    patch={~p"/meeting_rooms?page=#{@page - 1}&status=#{@filter_status}&keyword=#{@keyword}"}
    class={
      "px-4 py-2 rounded " <>
      if @page == 1, do: "bg-gray-300 text-gray-500 cursor-not-allowed", else: "bg-gray-200 hover:bg-gray-300"
    }
    aria-disabled={@page == 1}
  >
    Prev
  </.link>

  <!-- Page info -->
  <span>
    Page <%= @page %> of <%= Float.ceil(@total_count / @page_size) |> trunc() %>
  </span>

  <!-- Next button -->
  <.link
    patch={~p"/meeting_rooms?page=#{@page + 1}&status=#{@filter_status}&keyword=#{@keyword}"}
    class={
      "px-4 py-2 rounded " <>
      if @page * @page_size >= @total_count, do: "bg-gray-300 text-gray-500 cursor-not-allowed", else: "bg-gray-200 hover:bg-gray-300"
    }
    aria-disabled={@page * @page_size >= @total_count}
  >
    Next
  </.link>
</div>


<%= if @edit_modal_open do %>
  <div class="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
    <div class="bg-white rounded-2xl shadow-xl w-full max-w-lg p-8 relative">
      <button type="button"
              phx-click={JS.push("close_edit_modal")}
              class="absolute top-4 right-4 text-gray-400 hover:text-gray-600">✕</button>

      <h2 class="text-2xl font-bold mb-6">Kemaskini Bilik</h2>

      <.simple_form
        for={@edit_room_changeset}
        id="edit-room-form"
        phx-submit="update_room"
      >
        <.input field={@edit_room_changeset[:name]} type="text" label="Nama Bilik" />
        <.input field={@edit_room_changeset[:location]} type="text" label="Lokasi" />
        <.input field={@edit_room_changeset[:capacity]} type="number" label="Kapasiti" />
        <.input field={@edit_room_changeset[:status]} type="text" label="Status" />
        <.input field={@edit_room_changeset[:available_facility]} type="text" label="Fasiliti" />
        <.input field={@edit_room_changeset[:photo_url]} type="text" label="URL Foto" />

        <:actions>
          <button type="submit"
                  class="w-full py-2.5 bg-blue-600 text-white rounded-xl">
            Simpan Perubahan
          </button>
        </:actions>
      </.simple_form>
    </div>
  </div>
<% end %>
      </main>

        <!-- Modal Tambah Bilik -->
    <%= if @modal_open do %>
      <div class="fixed inset-0 bg-black/40 flex items-center justify-center z-50 animate-fade-in">
        <div class="bg-white rounded-2xl shadow-xl w-full max-w-lg p-8 relative animate-scale-in">
          <!-- Close Button -->
          <button
            type="button"
            phx-click={JS.push("close_modal")}
            class="absolute top-4 right-4 text-gray-400 hover:text-gray-600"
          >
            ✕
          </button>

          <h2 class="text-2xl font-bold mb-6 text-gray-800">Tambah Bilik Baru</h2>

          <.simple_form
            for={@new_room_changeset}
            id="meeting-room-form"
            phx-submit="save_room"
            class="space-y-4"
          >
            <.input field={@new_room_changeset[:name]} type="text" label="Nama Bilik" />
            <.input field={@new_room_changeset[:location]} type="text" label="Lokasi" />
            <.input field={@new_room_changeset[:capacity]} type="number" label="Kapasiti" />
            <.input field={@new_room_changeset[:status]} type="text" label="Status" />
            <.input field={@new_room_changeset[:available_facility]} type="text" label="Fasiliti" />
            <.input field={@new_room_changeset[:photo_url]} type="text" label="URL Foto" />

            <:actions>
              <button
                type="submit"
                class="w-full py-2.5 bg-blue-600 text-white rounded-xl hover:bg-blue-700 font-medium transition"
              >
                Simpan
              </button>
            </:actions>
          </.simple_form>
        </div>
      </div>
    <% end %>
  </div>
"""
  end
end

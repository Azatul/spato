defmodule SpatoWeb.MeetingRoomLive.Index do
    use SpatoWeb, :live_view
    import SpatoWeb.Components.Sidebar
    alias Spato.Facilities
    alias Spato.Facilities.MeetingRoom

    @impl true
    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:page_title, "Listing Meeting rooms")
       |> assign(:active_tab, "meeting_rooms")
       |> assign(:sidebar_open, true)
       |> assign(:current_user, nil)
       |> stream(:meeting_rooms, Facilities.list_meeting_rooms())}
    end

    @impl true
    def handle_params(params, _url, socket) do
      {:noreply, apply_action(socket, socket.assigns.live_action, params)}
    end

    defp apply_action(socket, :edit, %{"id" => id}) do
      socket
      |> assign(:page_title, "Edit Meeting room")
      |> assign(:meeting_room, Facilities.get_meeting_room!(id))
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
    def handle_event("delete", %{"id" => id}, socket) do
      meeting_room = Facilities.get_meeting_room!(id)
      {:ok, _} = Facilities.delete_meeting_room(meeting_room)

      {:noreply, stream_delete(socket, :meeting_rooms, meeting_room)}
    end

    @impl true
    def handle_event("toggle_sidebar", _params, socket) do
      {:noreply, assign(socket, :sidebar_open, !socket.assigns.sidebar_open)}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div class="flex w-screen h-screen bg-gray-100 font-sans overflow-hidden">
        <!-- Sidebar -->
        <.sidebar
          active_tab={@active_tab}
          current_user={@current_user}
          open={@sidebar_open}
          toggle_event="toggle_sidebar"
        />

        <!-- Main Content -->
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Tempahan Bilik Mesyuarat</title>
      <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
      <style>
          body {
              background-color: #f3f4f6;
          }
      </style>
  </head>
  <body class="font-sans">
      <div class="container mx-auto p-8">
          <div class="flex justify-between items-center mb-6">



              <div>
                  <h1 class="text-3xl font-bold text-gray-800">Tempahan Bilik Mesyuarat</h1>
                  <p class="text-gray-500">Tempah bilik mesyuarat dan uruskan tempahan anda</p>
              </div>
              <button class="bg-blue-500 text-white font-semibold py-2 px-6 rounded-md hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50">
                  + NEW BOOKING
              </button>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
              <div class="bg-white p-6 rounded-lg shadow-md flex items-center justify-between">
                  <div>
                      <h2 class="text-gray-500 text-sm uppercase font-semibold">Aktiviti Tempahan Bilik</h2>
                      <p class="text-4xl font-bold text-gray-800">4</p>
                      <p class="text-gray-400 text-sm">Minggu Ini</p>
                  </div>
                  <div class="text-gray-300 text-2xl">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                  </div>
              </div>
              <div class="bg-white p-6 rounded-lg shadow-md flex items-center justify-between">
                  <div>
                      <h2 class="text-gray-500 text-sm uppercase font-semibold">Menunggu Kelulusan</h2>
                      <p class="text-4xl font-bold text-gray-800">4</p>
                      <p class="text-gray-400 text-sm">Menunggu Jawapan</p>
                  </div>
                  <div class="text-gray-300 text-2xl">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                      </svg>
                  </div>
              </div>
              <div class="bg-white p-6 rounded-lg shadow-md flex items-center justify-between">
                  <div>
                      <h2 class="text-gray-500 text-sm uppercase font-semibold">Bulan Ini</h2>
                      <p class="text-4xl font-bold text-gray-800">4</p>
                      <p class="text-gray-400 text-sm">Tempahan Selesai</p>
                  </div>
                  <div class="text-gray-300 text-2xl">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-8 w-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                      </svg>
                  </div>
              </div>
          </div>

          <div class="bg-white p-6 rounded-lg shadow-md">
              <div class="flex justify-between items-center mb-4">
                  <h3 class="text-xl font-semibold text-gray-800">+ Tempahan Bilik Mesyuarat Saya</h3>
                  <button class="bg-gray-200 text-gray-700 font-semibold py-2 px-4 rounded-md hover:bg-gray-300 focus:outline-none">
                      Semua Status
                  </button>
              </div>

              <div class="overflow-x-auto">
                  <table class="w-full text-left">
                      <thead>
                          <tr class="text-gray-500 text-sm font-semibold border-b border-gray-200">
                              <th class="p-4">ID Tempahan</th>
                              <th class="p-4">Nama Bilik</th>
                              <th class="p-4">Ditempah Oleh</th>
                              <th class="p-4">Tarikh & Masa</th>
                              <th class="p-4">Tujuan</th>
                              <th class="p-4">Peserta</th>
                              <th class="p-4">Status</th>
                              <th class="p-4">Tindakan</th>
                          </tr>
                      </thead>
                      <tbody>
                          <tr class="border-b border-gray-200">
                              <td class="p-4 text-sm font-semibold text-gray-700">MRB-001</td>
                              <td class="p-4 text-gray-700 text-sm">Bilik Mesyuarat A<br><span class="text-xs text-gray-500">Tingkat 2, Sayap Timur</span></td>
                              <td class="p-4 text-gray-700 text-sm">John Smith<br><span class="text-xs text-gray-500">Pemasaran</span></td>
                              <td class="p-4 text-gray-700 text-sm">2025-05-02<br><span class="text-xs text-gray-500">11:00 - 12:00</span></td>
                              <td class="p-4 text-gray-700 text-sm">Mesyuarat Mingguan</td>
                              <td class="p-4 text-gray-700 text-sm">27</td>
                              <td class="p-4">
                                  <span class="bg-green-100 text-green-700 font-semibold py-1 px-3 rounded-full text-xs">Diluluskan</span>
                              </td>
                              <td class="p-4 text-sm">
                                  <a href="#" class="text-blue-500 hover:underline">view</a>
                              </td>
                          </tr>
                          <tr class="border-b border-gray-200">
                              <td class="p-4 text-sm font-semibold text-gray-700">MRB-002</td>
                              <td class="p-4 text-gray-700 text-sm">Bilik Mesyuarat B<br><span class="text-xs text-gray-500">Tingkat 1, Sayap Barat</span></td>
                              <td class="p-4 text-gray-700 text-sm">Diana<br><span class="text-xs text-gray-500">Kewangan</span></td>
                              <td class="p-4 text-gray-700 text-sm">2025-07-27<br><span class="text-xs text-gray-500">09:00 - 10:00</span></td>
                              <td class="p-4 text-gray-700 text-sm">Pembentangan Kewangan</td>
                              <td class="p-4 text-gray-700 text-sm">10</td>
                              <td class="p-4">
                                  <span class="bg-green-100 text-green-700 font-semibold py-1 px-3 rounded-full text-xs">Diluluskan</span>
                              </td>
                              <td class="p-4 text-sm">
                                  <a href="#" class="text-blue-500 hover:underline">view</a>
                              </td>
                          </tr>
                          <tr class="border-b border-gray-200">
                              <td class="p-4 text-sm font-semibold text-gray-700">MRB-003</td>
                              <td class="p-4 text-gray-700 text-sm">Bilik Mesyuarat C<br><span class="text-xs text-gray-500">Tingkat 4, Sayap Timur</span></td>
                              <td class="p-4 text-gray-700 text-sm">Haris<br><span class="text-xs text-gray-500">Operasi</span></td>
                              <td class="p-4 text-gray-700 text-sm">2025-08-06<br><span class="text-xs text-gray-500">11:00 - 12:00</span></td>
                              <td class="p-4 text-gray-700 text-sm">Pembentangan Hasil</td>
                              <td class="p-4 text-gray-700 text-sm">10</td>
                              <td class="p-4">
                                  <span class="bg-yellow-100 text-yellow-700 font-semibold py-1 px-3 rounded-full text-xs">Dalam Proses</span>
                              </td>
                              <td class="p-4 text-sm">
                                  <a href="#" class="text-blue-500 hover:underline">view</a>
                                  <a href="#" class="text-red-500 hover:underline ml-2">cancel</a>
                              </td>
                          </tr>
                          <tr>
                              <td class="p-4 text-sm font-semibold text-gray-700">MRB-004</td>
                              <td class="p-4 text-gray-700 text-sm">Bilik Mesyuarat D<br><span class="text-xs text-gray-500">Tingkat 2, Sayap Timur</span></td>
                              <td class="p-4 text-gray-700 text-sm">Diana<br><span class="text-xs text-gray-500">Kewangan</span></td>
                              <td class="p-4 text-gray-700 text-sm">2025-08-12<br><span class="text-xs text-gray-500">11:00 - 12:00</span></td>
                              <td class="p-4 text-gray-700 text-sm">Mesyuarat Jabatan</td>
                              <td class="p-4 text-gray-700 text-sm">6</td>
                              <td class="p-4">
                                  <span class="bg-yellow-100 text-yellow-700 font-semibold py-1 px-3 rounded-full text-xs">Dalam Proses</span>
                              </td>
                              <td class="p-4 text-sm">
                                  <a href="#" class="text-blue-500 hover:underline">view</a>
                                  <a href="#" class="text-red-500 hover:underline ml-2">cancel</a>
                              </td>
                          </tr>
                      </tbody>
                  </table>
              </div>
          </div>
      </div>
  </body>
        <div class="flex-1 overflow-y-auto">
          <div class="mx-auto max-w-4xl p-6">
            <div class="flex items-center justify-between mb-6">
              <h1 class="text-2xl font-bold"><%= @page_title %></h1>

              <.link
                patch={~p"/meeting_rooms/new"}
                class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                + New Meeting Room
              </.link>
            </div>

            <div class="bg-white shadow rounded-lg">
              <ul class="divide-y divide-gray-200">
                <%= for {id, meeting_room} <- @streams.meeting_rooms do %>
                  <li id={id} class="flex justify-between items-center p-4">
                    <span class="font-medium text-gray-800"><%= meeting_room.name %></span>
                    <div class="space-x-3">
                      <.link patch={~p"/meeting_rooms/#{meeting_room.id}/edit"} class="text-blue-600 hover:underline">
                        Edit
                      </.link>
                      <.link
                        phx-click="delete"
                        phx-value-id={meeting_room.id}
                        data-confirm="Are you sure?"
                        class="text-red-600 hover:underline"
                      >
                        Delete
                      </.link>
                    </div>
                  </li>
                <% end %>
              </ul>
            </div>
          </div>
        </div>
      </div>
      """
    end
  end

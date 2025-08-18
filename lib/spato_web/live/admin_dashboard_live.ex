defmodule SpatoWeb.AdminDashboardLive do
    use SpatoWeb, :live_view
    import SpatoWeb.Components.Sidebar

    on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

    def mount(_params, _session, socket) do
      if socket.assigns.current_user.role != "admin" do
        {:halt,
         socket
         |> put_flash(:error, "Access denied")
         |> redirect(to: "/dashboard")}
      else
        {:ok,
         socket
         |> assign(:page_title, "Admin Dashboard")
         |> assign(:active_tab, "admin_dashboard")
         |> assign(:sidebar_open, true)}
      end
    end

    def handle_event("toggle_sidebar", _params, socket) do
      {:noreply, update(socket, :sidebar_open, &(!&1))}
    end

    def render(assigns) do
      ~H"""
      <div class="flex h-screen">
        <.sidebar
          active_tab={@active_tab}
          current_user={@current_user}
          open={@sidebar_open}
          toggle_event="toggle_sidebar"
        />

      <main class="flex-1 p-6 transition-all duration-300">

      <body class="bg-gray-100 p-4 md:p-8">

          <!-- Top Section: Today's Reservations -->
          <section class="mb-8">
              <h2 class="text-xl md:text-2xl font-bold mb-4">Tempahan hari ini</h2>
              <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">

                  <!-- Card: Bilik mesyuarat (Meeting Room) -->
                  <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                      <div>
                          <p class="text-sm text-gray-500">Bilik mesyuarat</p>
                          <p class="text-3xl font-bold mt-1">12</p>
                      </div>
                      <div class="w-full flex justify-end">
                          <button class="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-1 px-4 rounded-md shadow-lg transition-colors mt-4 text-sm">
                              Ambil tindakan →
                          </button>
                      </div>
                  </div>

                  <!-- Card: Kenderaan (Vehicle) -->
                  <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                      <div>
                          <p class="text-sm text-gray-500">Kenderaan</p>
                          <p class="text-3xl font-bold mt-1">8</p>
                      </div>
                      <div class="w-full flex justify-end">
                          <button class="bg-green-600 hover:bg-green-700 text-white font-semibold py-1 px-4 rounded-md shadow-lg transition-colors mt-4 text-sm">
                              Ambil tindakan →
                          </button>
                      </div>
                  </div>

                  <!-- Card: Katering (Catering) -->
                  <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                      <div>
                          <p class="text-sm text-gray-500">Katering</p>
                          <p class="text-3xl font-bold mt-1">4</p>
                      </div>
                      <div class="w-full flex justify-end">
                          <button class="bg-yellow-500 hover:bg-yellow-700 text-white font-semibold py-1 px-4 rounded-md shadow-lg transition-colors mt-4 text-sm">
                              Ambil tindakan →
                          </button>
                      </div>
                  </div>

                  <!-- Card: Peralatan (Equipment) -->
                  <div class="bg-white p-6 rounded-xl shadow-md flex flex-col justify-between h-40 transition-transform hover:scale-105">
                      <div>
                          <p class="text-sm text-gray-500">Peralatan</p>
                          <p class="text-3xl font-bold mt-1">12</p>
                      </div>
                      <div class="w-full flex justify-end">
                          <button class="bg-red-600 hover:bg-red-700 text-white font-semibold py-1 px-4 rounded-md shadow-lg transition-colors mt-4 text-sm">
                              Ambil tindakan →
                          </button>
                      </div>
                  </div>
              </div>
          </section>

          <!-- Calendar Section -->
          <section class="bg-white p-4 md:p-8 rounded-xl shadow-md">
              <h2 class="text-xl md:text-2xl font-bold mb-6">Kalendar Tempahan</h2>

              <!-- Filter and Navigation Bar -->
              <div class="flex flex-wrap items-center justify-between gap-4 mb-6">
                  <div class="flex flex-wrap items-center gap-4">
                      <!-- Dropdown filter -->
                      <div class="flex items-center space-x-2">
                          <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                              <path fill-rule="evenodd" d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clip-rule="evenodd" />
                          </svg>
                          <select class="border border-gray-300 rounded-lg p-2 text-gray-700 focus:ring-blue-500 focus:border-blue-500">
                              <option>Jenis tempahan</option>
                          </select>
                      </div>

                      <!-- Day/Week/Month buttons -->
                      <div class="flex items-center space-x-1 border border-gray-300 rounded-lg p-1">
                          <button class="px-4 py-2 bg-white text-gray-700 font-semibold rounded-lg hover:bg-gray-200 transition-colors">Hari</button>
                          <button class="px-4 py-2 bg-blue-600 text-white font-semibold rounded-lg shadow-md transition-colors">Minggu</button>
                          <button class="px-4 py-2 bg-white text-gray-700 font-semibold rounded-lg hover:bg-gray-200 transition-colors">Bulan</button>
                      </div>
                  </div>

                  <!-- Date range pickers -->
                  <div class="flex flex-wrap items-center gap-4">
                      <div class="flex items-center space-x-2">
                          <p class="text-gray-700 whitespace-nowrap">Dari</p>
                          <div class="flex items-center border border-gray-300 rounded-lg p-2 bg-white">
                              <input type="text" placeholder="dd/mm/yyyy" class="outline-none w-28 text-gray-700">
                              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                                  <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd" />
                              </svg>
                          </div>
                      </div>
                      <div class="flex items-center space-x-2">
                          <p class="text-gray-700 whitespace-nowrap">Hingga</p>
                          <div class="flex items-center border border-gray-300 rounded-lg p-2 bg-white">
                              <input type="text" placeholder="dd/mm/yyyy" class="outline-none w-28 text-gray-700">
                              <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor">
                                  <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd" />
                              </svg>
                          </div>
                      </div>
                  </div>
              </div>

              <!-- Calendar Grid -->
              <div class="overflow-x-auto rounded-lg border border-gray-200">

              </div>
          </section>

      </body>
        </main>
      </div>
      """
    end
  end

defmodule SpatoWeb.UserDashboardLive do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    stats = Spato.Bookings.get_user_booking_stats(user.id)

    {:ok,
     socket
     |> assign(:page_title, "User Dashboard")
     |> assign(:active_tab, "dashboard")
     |> assign(:sidebar_open, true)
     |> assign(:stats, stats)}
  end

  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  def handle_event("refresh_stats", _params, socket) do
    user = socket.assigns.current_user
    stats = Spato.Bookings.get_user_booking_stats(user.id)
    {:noreply, assign(socket, :stats, stats)}
  end

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

      <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

      <!-- Main Content -->
      <main class="flex-1 pt-20 p-8 overflow-y-auto bg-gray-50">

        <!-- Welcome -->
        <div class="mb-8">
          <h1 class="text-3xl font-bold text-gray-800">Selamat Kembali, <%= if @current_user.user_profile do %><%= @current_user.user_profile.full_name %><% else %><%= @current_user.email %><% end %>!</h1>
          <p class="text-gray-500 mt-1">
            Berikut ialah ikhtisar ringkas tempahan dan aktiviti anda
          </p>
        </div>

        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <!-- Total Bookings This Week -->
          <div class="bg-gradient-to-br from-blue-500 to-blue-600 p-6 rounded-xl shadow-lg text-white transform hover:scale-105 transition-all duration-300">
            <div class="flex justify-between items-start">
              <div>
                <h3 class="text-blue-100 text-sm font-semibold">Tempahan Minggu Ini</h3>
                <p class="text-4xl font-bold mt-2"><%= @stats.total %></p>
                <p class="text-blue-100 text-sm mt-1">Jumlah Keseluruhan</p>
              </div>
              <i class="fa-solid fa-calendar-days text-blue-200 text-3xl"></i>
            </div>
          </div>

          <!-- Pending Approvals -->
          <div class="bg-gradient-to-br from-yellow-500 to-orange-500 p-6 rounded-xl shadow-lg text-white transform hover:scale-105 transition-all duration-300">
            <div class="flex justify-between items-start">
              <div>
                <h3 class="text-yellow-100 text-sm font-semibold">Menunggu Kelulusan</h3>
                <p class="text-4xl font-bold mt-2"><%= @stats.pending %></p>
                <p class="text-yellow-100 text-sm mt-1">Dalam Proses</p>
              </div>
              <i class="fa-solid fa-clock text-yellow-200 text-3xl"></i>
            </div>
          </div>

          <!-- Approved Bookings -->
          <div class="bg-gradient-to-br from-green-500 to-emerald-500 p-6 rounded-xl shadow-lg text-white transform hover:scale-105 transition-all duration-300">
            <div class="flex justify-between items-start">
              <div>
                <h3 class="text-green-100 text-sm font-semibold">Diluluskan</h3>
                <p class="text-4xl font-bold mt-2"><%= @stats.approved %></p>
                <p class="text-green-100 text-sm mt-1">Tempahan Aktif</p>
              </div>
              <i class="fa-solid fa-check-circle text-green-200 text-3xl"></i>
            </div>
          </div>

          <!-- Completed Bookings -->
          <div class="bg-gradient-to-br from-purple-500 to-indigo-500 p-6 rounded-xl shadow-lg text-white transform hover:scale-105 transition-all duration-300">
            <div class="flex justify-between items-start">
              <div>
                <h3 class="text-purple-100 text-sm font-semibold">Selesai</h3>
                <p class="text-4xl font-bold mt-2"><%= @stats.completed %></p>
                <p class="text-purple-100 text-sm mt-1">Tempahan Lengkap</p>
              </div>
              <i class="fa-solid fa-flag-checkered text-purple-200 text-3xl"></i>
            </div>
          </div>
        </div>

      <!-- Action Buttons (Blue Theme) -->
          <div class="flex justify-center space-x-4 mb-8">
            <!-- Blue -->
            <button class="flex items-center px-4 py-2 bg-blue-400 text-slate-800 rounded-lg shadow-md hover:bg-blue-500">
              <i class="fa-solid fa-plus mr-2"></i> Tempah Bilik Mesyuarat
            </button>
            <!-- Cyan -->
            <button class="flex items-center px-4 py-2 bg-cyan-300 text-slate-800 rounded-lg shadow-md hover:bg-cyan-400">
              <i class="fa-solid fa-plus mr-2"></i> Tempah Kenderaan
            </button>
            <!-- Indigo -->
            <button class="flex items-center px-4 py-2 bg-indigo-300 text-slate-800 rounded-lg shadow-md hover:bg-indigo-400">
              <i class="fa-solid fa-plus mr-2"></i> Tempah Katering
            </button>
            <!-- Slate -->
            <button class="flex items-center px-4 py-2 bg-slate-300 text-slate-800 rounded-lg shadow-md hover:bg-slate-400">
              <i class="fa-solid fa-plus mr-2"></i> Tempah Peralatan
            </button>
          </div>



        <!-- Calendar Table -->
        <div class="bg-white p-6 rounded-lg shadow-md min-h-[400px]">
          <h3 class="text-xl font-bold text-gray-800 mb-2">Kalendar Tempahan Saya</h3>
          <p class="text-gray-500 mb-4">Tempahan yang diluluskan</p>

          <div class="flex items-center justify-between mb-4 flex-wrap gap-4">
            <div class="flex items-center space-x-2">
              <span class="text-gray-600">Jenis tempahan</span>
              <select class="border rounded-md p-2 w-64">
                <option>Tempahan Bilik Mesyuarat</option>
              </select>
            </div>
            <div class="flex space-x-2">
              <button class="px-4 py-2 bg-blue-600 text-white rounded-md">Hari</button>
              <button class="px-4 py-2 bg-gray-200 text-gray-800 rounded-md">Minggu</button>
              <button class="px-4 py-2 bg-gray-200 text-gray-800 rounded-md">Bulan</button>
            </div>
            <div class="flex items-center space-x-2">
              <span class="text-gray-600">Dari</span>
              <input type="date" class="border rounded-md p-2 w-35" />
              <span class="text-gray-600">Hingga</span>
              <input type="date" class="border rounded-md p-2 w-35" />
            </div>
          </div>

          <div class="overflow-x-auto">
            <table class="min-w-full bg-white border border-gray-200 rounded-lg">
              <thead>
                <tr class="bg-gray-100">
                  <th class="px-4 py-2 border-r border-gray-200 text-left text-sm font-semibold text-gray-700 w-48">
                    Tempahan Bilik Mesyuarat hari ini
                  </th>
                  <th class="px-4 py-2 border-r border-gray-200 text-sm font-semibold text-gray-700 w-32">08:00-09:00</th>
                  <th class="px-4 py-2 border-r border-gray-200 text-sm font-semibold text-gray-700 w-32">09:00-10:00</th>
                  <th class="px-4 py-2 border-r border-gray-200 text-sm font-semibold text-gray-700 w-32">10:00-11:00</th>
                  <th class="px-4 py-2 text-sm font-semibold text-gray-700 w-32">11:00-12:00</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td class="px-4 py-2 border-r border-gray-200 border-t text-sm text-gray-600">18/09/2024</td>
                  <td colspan="2" class="px-4 py-2 border-r border-t bg-blue-200 text-blue-800 text-sm">
                    <div class="font-semibold">Bilik Mesyuarat A</div>
                    <div class="text-xs">Tingkat 2, Sayap Timur</div>
                  </td>
                  <td class="px-4 py-2 border-r border-t"></td>
                  <td class="px-4 py-2 border-t"></td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
    """
  end

end

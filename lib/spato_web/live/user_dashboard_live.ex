defmodule SpatoWeb.UserDashboardLive do
  use SpatoWeb, :live_view

  import SpatoWeb.Sidebar

  alias Spato.Accounts
  alias Spato.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.list_users()

    {:ok,
      socket
      |> assign(:page_title, "User Dashboard")
      |> assign(:users, users)
      |> assign(:search_term, "")
    }
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    users =
      Accounts.list_users()
      |> Enum.filter(fn user ->
        String.contains?(String.downcase(user.email), String.downcase(query))
      end)

    {:noreply, assign(socket, :users, users)}
  end

  @impl true
def render(assigns) do
  ~H"""
  <div class="flex w-screen h-screen bg-gray-100 font-sans overflow-hidden">
    <!-- Sidebar -->
    <div class="w-64 h-full bg-white shadow-md flex-shrink-0">
      <.sidebar />
    </div>

    <!-- Main Content -->
    <main class="flex-1 p-8 overflow-y-auto bg-gray-50">
      <!-- Header -->
      <div class="flex justify-between items-center pb-4 mb-8 border-b border-gray-200">
        <h2 class="text-xl font-semibold">User Panel</h2>
        <div class="flex items-center space-x-2">
          <span class="text-gray-700">Arissa</span>
          <div class="w-10 h-10 bg-gray-300 rounded-full flex items-center justify-center">
            <i class="fa-solid fa-user text-gray-600"></i>
          </div>
        </div>
      </div>

      <!-- Welcome -->
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-800">Selamat Kembali, Arissa!</h1>
        <p class="text-gray-500 mt-1">
          Berikut ialah ikhtisar ringkas tempahan dan aktiviti anda
        </p>
      </div>

      <!-- Cards -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-white p-6 rounded-lg shadow-md flex justify-between items-start min-h-[120px]">
          <div>
            <h3 class="text-gray-500 text-sm font-semibold">Aktiviti Tempahan</h3>
            <p class="text-4xl font-bold text-gray-800 mt-2">4</p>
            <p class="text-gray-500 text-sm mt-1">Minggu Ini</p>
          </div>
          <i class="fa-solid fa-calendar-days text-gray-400 text-2xl"></i>
        </div>

        <div class="bg-white p-6 rounded-lg shadow-md flex justify-between items-start min-h-[120px]">
          <div>
            <h3 class="text-gray-500 text-sm font-semibold">Menunggu Kelulusan</h3>
            <p class="text-4xl font-bold text-gray-800 mt-2">4</p>
            <p class="text-gray-500 text-sm mt-1">Menunggu Jawapan</p>
          </div>
          <i class="fa-solid fa-clock text-gray-400 text-2xl"></i>
        </div>

        <div class="bg-white p-6 rounded-lg shadow-md flex justify-between items-start min-h-[120px]">
          <div>
            <h3 class="text-gray-500 text-sm font-semibold">Jumlah Bulan Ini</h3>
            <p class="text-4xl font-bold text-gray-800 mt-2">4</p>
            <p class="text-gray-500 text-sm mt-1">Tempahan Selesai</p>
          </div>
          <i class="fa-solid fa-sync-alt text-gray-400 text-2xl"></i>
        </div>
      </div>

      <!-- Action Buttons -->
      <div class="flex space-x-4 mb-8">
        <button class="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg shadow-md hover:bg-blue-700">
          <i class="fa-solid fa-plus mr-2"></i> Tempah Bilik Mesyuarat
        </button>
        <button class="flex items-center px-4 py-2 bg-green-500 text-white rounded-lg shadow-md hover:bg-green-600">
          <i class="fa-solid fa-plus mr-2"></i> Tempah Kenderaan
        </button>
        <button class="flex items-center px-4 py-2 bg-yellow-500 text-white rounded-lg shadow-md hover:bg-yellow-600">
          <i class="fa-solid fa-plus mr-2"></i> Tempah Katering
        </button>
        <button class="flex items-center px-4 py-2 bg-red-500 text-white rounded-lg shadow-md hover:bg-red-600">
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
            <select class="border rounded-md p-2">
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
            <input type="date" class="border rounded-md p-2 w-32" />
            <span class="text-gray-600">Hingga</span>
            <input type="date" class="border rounded-md p-2 w-32" />
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

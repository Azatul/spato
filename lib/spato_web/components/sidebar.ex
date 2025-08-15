# lib/spato_web/components/sidebar.ex
defmodule SpatoWeb.Sidebar do
  use Phoenix.Component

  # Komponen ini boleh dipanggil dengan: <.sidebar />
  def sidebar(assigns) do
    ~H"""
    <aside class="bg-white w-64 p-4 shadow-md flex-shrink-0">
      <div class="flex items-center space-x-2 pb-4 border-b border-gray-200">
        <img src="https://placehold.co/40x40" alt="SPATO Logo" class="w-10 h-10" />
        <h1 class="font-bold text-lg text-blue-700">SPATO</h1>
      </div>
      <nav class="mt-8">
        <ul>
          <li class="mb-2">
            <a href="#" class="flex items-center p-2 text-blue-700 bg-blue-100 rounded-md">
              <i class="fa-solid fa-chart-line w-5 h-5 mr-3"></i>
              Dashboard
            </a>
          </li>
          <li class="mb-2">
            <a href="#" class="flex items-center p-2 text-gray-600 hover:bg-gray-100 rounded-md">
              <i class="fa-solid fa-building w-5 h-5 mr-3"></i>
              Tempahan Bilik Mesyuarat
            </a>
          </li>
          <li class="mb-2">
            <a href="#" class="flex items-center p-2 text-gray-600 hover:bg-gray-100 rounded-md">
              <i class="fa-solid fa-list-check w-5 h-5 mr-3"></i>
              Tempahan
            </a>
          </li>
          <li class="ml-4 mb-2">
            <a href="#" class="block p-2 text-gray-600 hover:bg-gray-100 rounded-md">
              Tempahan Bilik Mesyuarat
            </a>
          </li>
          <li class="ml-4 mb-2">
            <a href="#" class="block p-2 text-gray-600 hover:bg-gray-100 rounded-md">
              Tempahan Kenderaan
            </a>
          </li>
          <li class="ml-4 mb-2">
            <a href="#" class="block p-2 text-gray-600 hover:bg-gray-100 rounded-md">
              Tempahan Katering
            </a>
          </li>
          <li class="ml-4 mb-2">
            <a href="#" class="block p-2 text-gray-600 hover:bg-gray-100 rounded-md">
              Tempahan Peralatan
            </a>
          </li>
          <li class="mb-2">
            <a href="#" class="flex items-center p-2 text-gray-600 hover:bg-gray-100 rounded-md">
              <i class="fa-solid fa-history w-5 h-5 mr-3"></i>
              Sejarah Tempahan Saya
            </a>
          </li>
        </ul>
      </nav>
    </aside>
    """
  end
end

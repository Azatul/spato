defmodule SpatoWeb.Components.Sidebar do
  use Phoenix.Component

  # The attr for @socket is needed to correctly use Routes.static_path.
  attr :active_tab, :string, default: nil
  attr :current_user, :map, required: true
  attr :open, :boolean, default: true
  attr :toggle_event, :string, default: nil

  def sidebar(assigns) do
    ~H"""
    <aside
      class={[
        "h-full bg-gray-100 border-r border-gray-200 p-4 flex flex-col transition-all duration-300 overflow-y-auto",
        @open && "w-64",
        !@open && "w-16"
      ]}
    >
      <!-- Logo section at the top of the sidebar -->
      <div class="mb-6">
        <img
          src="/images/logo.png"
          alt="Spato Logo"
          class={[
            "mx-auto h-12 transition-transform duration-300",
            @open && "scale-100",
            !@open && "scale-0"
          ]}
        />
      </div>

      <!-- Toggle button -->
      <div class="flex justify-end mb-4">
        <button
          phx-click={@toggle_event}
          class="w-8 h-8 flex items-center justify-center bg-blue-500 text-white rounded-full hover:bg-blue-600 transition-colors"
          title="Toggle sidebar"
        >
          <i class={
            if @open,
              do: "fa-solid fa-angle-left",
              else: "fa-solid fa-angle-right"
          }></i>
        </button>
      </div>

      <nav class="flex-1">
        <ul class="space-y-2">

          <!-- Dashboard -->
          <li>
            <.sidebar_link
              to="/admin/dashboard"
              icon="house"
              active={@active_tab == "dashboard"}
              open={@open}
            >
              Dashboard
            </.sidebar_link>
          </li>

          <!-- Tempahan submenu -->
          <li>
            <details class="group">
              <summary class={[
                "flex items-center justify-between px-4 py-2 rounded-md hover:bg-gray-200 cursor-pointer",
                @active_tab in ["meeting_rooms", "vehicles", "catering", "equipments", "history"] && "bg-gray-300 font-bold"
              ]}>
                <div class="flex items-center gap-2">
                  <i class="fa-solid fa-calendar-check"></i>
                  <%= if @open, do: "Tempahan" %>
                </div>
                <%= if @open do %>
                  <i class="fa-solid fa-angle-down transition-transform group-open:rotate-180"></i>
                <% end %>
              </summary>

              <ul class="ml-8 mt-2 space-y-1">
                <li><.sidebar_link to="/meeting_rooms" icon="door-closed" active={@active_tab == "meeting_rooms"} open={@open}>Tempahan Bilik Mesyuarat</.sidebar_link></li>
                <li><.sidebar_link to="/vehicles" icon="car" active={@active_tab == "vehicles"} open={@open}>Tempahan Kenderaan</.sidebar_link></li>
                <li><.sidebar_link to="/catering" icon="utensils" active={@active_tab == "catering"} open={@open}>Tempahan Katering</.sidebar_link></li>
                <li><.sidebar_link to="/equipments" icon="tools" active={@active_tab == "equipments"} open={@open}>Tempahan Peralatan</.sidebar_link></li>
                <li><.sidebar_link to="/history" icon="clock-rotate-left" active={@active_tab == "history"} open={@open}>Sejarah Tempahan</.sidebar_link></li>
              </ul>
            </details>
          </li>

          <!-- Admin-only items -->
          <%= if is_admin?(@current_user) do %>
            <li>
              <details class="group">
                <summary class={[
                  "flex items-center justify-between px-4 py-2 rounded-md hover:bg-gray-200 cursor-pointer",
                  @active_tab in ["manage_meeting_rooms", "manage_vehicles", "manage_catering", "manage_equipments"] && "bg-gray-300 font-bold"
                ]}>
                  <div class="flex items-center gap-2">
                    <i class="fa-solid fa-boxes-stacked"></i>
                    <%= if @open, do: "Pengurusan Aset" %>
                  </div>
                  <%= if @open do %>
                    <i class="fa-solid fa-angle-down transition-transform group-open:rotate-180"></i>
                  <% end %>
                </summary>

                <ul class="ml-8 mt-2 space-y-1">
                  <li><.sidebar_link to="/manage_meeting_rooms" icon="door-open" active={@active_tab == "manage_meeting_rooms"} open={@open}>Urus Bilik Mesyuarat</.sidebar_link></li>
                  <li><.sidebar_link to="/manage_vehicles" icon="truck" active={@active_tab == "manage_vehicles"} open={@open}>Urus Kenderaan</.sidebar_link></li>
                  <li><.sidebar_link to="/manage_catering" icon="utensils" active={@active_tab == "manage_catering"} open={@open}>Urus Katering</.sidebar_link></li>
                  <li><.sidebar_link to="/manage_equipments" icon="tools" active={@active_tab == "manage_equipments"} open={@open}>Urus Peralatan</.sidebar_link></li>
                </ul>
              </details>
            </li>

            <li>
              <.sidebar_link to="/users" icon="users" active={@active_tab == "users"} open={@open}>
                Senarai Pengguna
              </.sidebar_link>
            </li>
            <li>
              <.sidebar_link to="/statistik" icon="chart-bar" active={@active_tab == "statistik"} open={@open}>
                Statistik
              </.sidebar_link>
            </li>
          <% end %>
        </ul>
      </nav>
    </aside>
    """
  end

  attr :to, :string, required: true
  attr :icon, :string, required: true
  attr :active, :boolean, default: false
  attr :open, :boolean, default: true
  slot :inner_block, required: true

  def sidebar_link(assigns) do
    ~H"""
    <a
      href={@to}
      class={[
        "flex items-center gap-2 px-4 py-2 rounded-md hover:bg-gray-200 transition-all duration-300",
        @active && "bg-gray-300 font-bold"
      ]}
    >
      <i class={"fa-solid fa-#{@icon}"}></i>
      <%= if @open do %>
        <span><%= render_slot(@inner_block) %></span>
      <% end %>
    </a>
    """
  end

  defp is_admin?(%{role: "admin"}), do: true
  defp is_admin?(_), do: false
end

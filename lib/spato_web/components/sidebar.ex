defmodule SpatoWeb.Components.Sidebar do
  use Phoenix.Component
  import SpatoWeb.CoreComponents, only: [icon: 1]

  attr :active_tab, :string, default: nil
  attr :current_user, :map, required: true
  attr :open, :boolean, default: true
  attr :toggle_event, :string, default: nil

  def sidebar(assigns) do
    ~H"""
      <aside class={[
        "h-full bg-white-100 border-r border-gray-200 p-4 flex flex-col transition-all duration-300 overflow-hidden",
        @open && "w-64",
        !@open && "w-20"
      ]}>

      <!-- Logo -->
      <div class="flex items-center transition-all duration-300 cursor-pointer h-16 px-3"
           phx-click={@toggle_event} title="Toggle sidebar">
        <div class="flex-shrink-0 flex items-center justify-center w-8 h-8">
          <img src="/images/spato - logo.png" alt="Spato Icon" class="h-8 w-8" />
        </div>
        <img src="/images/spato - word.png" alt="Spato Logo"
             class={[
               "h-5 transition-all duration-300 origin-left ml-2",
               @open && "opacity-100 scale-x-100",
               !@open && "opacity-0 scale-x-0"
             ]} />
      </div>

      <!-- Navigation -->
      <nav class="flex-1 flex flex-col">
        <ul class="space-y-2">
          <!-- Dashboard -->
          <li>
            <%= if @open do %>
              <.link
                patch={if @current_user.role == "admin", do: "/admin/dashboard", else: "/dashboard"}
                class={[
                  "flex items-center gap-2 px-4 py-2 rounded-md hover:bg-gray-200 transition-all duration-300",
                  @active_tab in ["dashboard", "admin_dashboard"] && "bg-gray-300 font-bold"
                ]}>
                <.icon name="hero-home" class="w-5 h-5" />
                Dashboard
              </.link>
            <% else %>
              <div class="flex items-center justify-center px-4 py-2">
                <.icon name="hero-home" class="w-5 h-5" />
              </div>
            <% end %>
          </li>

         <!-- Tempahan Menu -->
          <li>
            <%= if @open do %>
              <details
                class="group"
                open={@active_tab in ["admin_meeting_rooms", "meeting_rooms", "vehicles", "admin_vehicles", "catering", "admin_catering", "equipments", "admin_equipments"]}>
                <summary class="flex items-center justify-between px-4 py-2 rounded-md hover:bg-gray-200 cursor-pointer">
                  <div class="flex items-center gap-2">
                    <.icon name="hero-calendar" class="w-5 h-5" />
                    <span>Tempahan</span>
                  </div>
                  <.icon name="hero-chevron-down-solid" class="w-4 h-4 transition-transform group-open:rotate-180" />
                </summary>

                <ul class="ml-8 mt-2 space-y-1">
                  <li>
                    <.sidebar_link
                      patch={if @current_user.role == "admin", do: "/admin/meeting_room_bookings", else: "/meeting_room_bookings"}
                      active={@active_tab in ["meeting_rooms", "admin_meeting_rooms"]}
                      open={@open}>
                      Tempahan Bilik Mesyuarat
                    </.sidebar_link>
                  </li>
                  <li>
                    <.sidebar_link
                      patch={if @current_user.role == "admin", do: "/admin/vehicle_bookings", else: "/vehicle_bookings"}
                      active={@active_tab in ["vehicles", "admin_vehicles"]}
                      open={@open}>
                      Tempahan Kenderaan
                    </.sidebar_link>
                  </li>
                  <li>
                    <.sidebar_link
                      patch={if @current_user.role == "admin", do: "/admin/catering_bookings", else: "/catering_bookings"}
                      active={@active_tab in ["catering", "admin_catering"]}
                      open={@open}>
                      Tempahan Katering
                    </.sidebar_link>
                  </li>
                  <li>
                    <.sidebar_link
                      patch={if @current_user.role == "admin", do: "/admin/equipment_bookings", else: "/equipment_bookings"}
                      active={@active_tab in ["equipments", "admin_equipments"]}
                      open={@open}>
                      Tempahan Peralatan
                    </.sidebar_link>
                  </li>
                </ul>
              </details>
            <% else %>
              <!-- Closed sidebar: show only the icon -->
              <div class="flex items-center justify-center px-4 py-2" title="Tempahan">
                <.icon name="hero-calendar" class="w-5 h-5" />
              </div>
            <% end %>
          </li>

          <!-- Sejarah Tempahan (only for users, mid menu) -->
          <%= if @current_user.role == "user" do %>
            <li class="mt-auto">
                <%= if @open do %>
                  <.link
                    patch="/booking_history"
                    class={[
                      "flex items-center gap-2 px-4 py-2 rounded-md hover:bg-gray-200 transition-all duration-300",
                      @active_tab == "history" && "bg-gray-300 font-bold"
                    ]}>
                    <.icon name="hero-clock" class="w-5 h-5" />
                    Sejarah Tempahan
                  </.link>
                <% else %>
                  <div class="flex items-center justify-center px-4 py-2" title="Sejarah Tempahan">
                    <.icon name="hero-clock" class="w-5 h-5" />
                  </div>
                <% end %>
              </li>
          <% end %>

          <!-- Admin Menu -->
            <%= if is_admin?(@current_user) do %>
              <li>
                <%= if @open do %>
                  <!-- Show submenu only when sidebar is open -->
                  <details
                    class="group"
                    open={@active_tab in ["manage_meeting_rooms", "manage_vehicles", "manage_catering", "manage_equipments"]}>
                    <summary class="flex items-center justify-between px-4 py-2 rounded-md hover:bg-gray-200 cursor-pointer">
                      <div class="flex items-center gap-2">
                        <.icon name="hero-cube-transparent-solid" class="w-5 h-5" />
                        Pengurusan Aset
                      </div>
                      <.icon name="hero-chevron-down-solid" class="w-4 h-4 transition-transform group-open:rotate-180" />
                    </summary>
                    <ul class="ml-8 mt-2 space-y-1">
                      <li>
                        <.sidebar_link patch="/admin/meeting_rooms" active={@active_tab == "manage_meeting_rooms"} open={@open}>
                          Urus Bilik Mesyuarat
                        </.sidebar_link>
                      </li>
                      <li>
                        <.sidebar_link patch="/admin/vehicles" active={@active_tab == "manage_vehicles"} open={@open}>
                          Urus Kenderaan
                        </.sidebar_link>
                      </li>
                      <li>
                        <.sidebar_link patch="/admin/catering_menus" active={@active_tab == "manage_catering"} open={@open}>
                          Urus Katering
                        </.sidebar_link>
                      </li>
                      <li>
                        <.sidebar_link patch="/admin/equipments" active={@active_tab == "manage_equipments"} open={@open}>
                          Urus Peralatan
                        </.sidebar_link>
                      </li>
                    </ul>
                  </details>
                <% else %>
                  <!-- Only icon when sidebar is closed -->
                  <div class="flex items-center justify-center px-4 py-2">
                    <.icon name="hero-cube-transparent-solid" class="w-5 h-5" />
                  </div>
                <% end %>
              </li>

            <!-- Senarai Pengguna -->
              <li>
                <%= if @open do %>
                  <.link patch="/admin/user_profiles"
                    class={[
                      "flex items-center gap-2 px-4 py-2 rounded-md hover:bg-gray-200 transition-all duration-300",
                      @active_tab == "user_profiles" && "bg-gray-300 font-bold"
                    ]}>
                    <.icon name="hero-users" class="w-5 h-5" /> Senarai Pengguna
                  </.link>
                <% else %>
                  <div class="flex items-center justify-center px-4 py-2" title="Senarai Pengguna">
                    <.icon name="hero-users" class="w-5 h-5" />
                  </div>
                <% end %>
              </li>

              <!-- Senarai Jabatan -->
              <li>
                <%= if @open do %>
                  <.link patch="/admin/departments"
                    class={[
                      "flex items-center gap-2 px-4 py-2 rounded-md hover:bg-gray-200 transition-all duration-300",
                      @active_tab == "departments" && "bg-gray-300 font-bold"
                    ]}>
                    <.icon name="hero-building-office-2" class="w-5 h-5" /> Senarai Jabatan
                  </.link>
                <% else %>
                  <div class="flex items-center justify-center px-4 py-2" title="Senarai Jabatan">
                    <.icon name="hero-building-office-2" class="w-5 h-5" />
                  </div>
                <% end %>
              </li>

              <!-- Sejarah Tempahan at very bottom for admins -->
              <li class="mt-auto">
                <%= if @open do %>
                  <.link
                    patch="/admin/booking_history"
                    class={[
                      "flex items-center gap-2 px-4 py-2 rounded-md hover:bg-gray-200 transition-all duration-300",
                      @active_tab == "admin_history" && "bg-gray-300 font-bold"
                    ]}>
                    <.icon name="hero-clock" class="w-5 h-5" />
                    Sejarah Tempahan
                  </.link>
                <% else %>
                  <div class="flex items-center justify-center px-4 py-2" title="Sejarah Tempahan">
                    <.icon name="hero-clock" class="w-5 h-5" />
                  </div>
                <% end %>
              </li>
          <% end %>
        </ul>
      </nav>
    </aside>
    """
  end

  # ----------------------------
  attr :patch, :string, required: true
  attr :active, :boolean, default: false
  attr :open, :boolean, default: true
  slot :inner_block, required: true
  def sidebar_link(assigns) do
    ~H"""
    <.link patch={@patch}
           class={"flex items-center gap-2 px-4 py-2 rounded-md hover:bg-gray-200 transition-all duration-300 " <>
                  if @active, do: "bg-gray-300 font-bold", else: ""}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp is_admin?(%{role: "admin"}), do: true
  defp is_admin?(_), do: false
end

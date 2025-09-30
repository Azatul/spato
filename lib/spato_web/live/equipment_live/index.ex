defmodule SpatoWeb.EquipmentLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Assets
  alias Spato.Assets.Equipment

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Senarai Peralatan")
     |> assign(:active_tab, "manage_equipments")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:filter_status, "all")
     |> assign(:filter_type, "all")
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> stream(:equipments, Assets.list_equipments())}
  end

  # --- LOAD EQUIPMENTS ---
  defp load_equipments(socket) do
    params = %{
      "page" => socket.assigns.page,
      "search" => socket.assigns.search_query,
      "status" => socket.assigns.filter_status,
      "type" => socket.assigns.filter_type
    }

    data = Assets.list_equipments_paginated(params)

     # Global stats (not affected by filters)
      all_equipments = Assets.list_equipments()
      stats = %{
        total: length(all_equipments),
        available: Enum.count(all_equipments, &(&1.status == "tersedia")),
        maintenance: Enum.count(all_equipments, &(&1.status == "tidak_tersedia")),
        active: Enum.count(all_equipments, &(&1.status == "tersedia"))
      }

    socket
    |> assign(:equipments_page, data.equipments_page)
    |> assign(:total_pages, data.total_pages)
    |> assign(:stats, stats)
    |> assign(:filtered_count, data.total)
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 1)
     |> load_equipments()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
    push_patch(socket,
      to:
        ~p"/admin/equipments?page=1&q=#{socket.assigns.search_query}&status=#{status}&type=#{socket.assigns.filter_type}"
    )}
  end

  @impl true
  def handle_event("filter_type", %{"type" => type}, socket) do
    {:noreply,
    push_patch(socket,
      to:
        ~p"/admin/equipments?page=1&q=#{socket.assigns.search_query}&status=#{socket.assigns.filter_status}&type=#{type}"
    )}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, String.to_integer(page))
     |> load_equipments()}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket), do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    equipment = Assets.get_equipment!(id)
    {:ok, _} = Assets.delete_equipment(equipment)
    {:noreply, load_equipments(socket)}
  end

  @impl true
  def handle_info({SpatoWeb.EquipmentLive.FormComponent, {:saved, _equipment}}, socket) do
    {:noreply, load_equipments(socket)}
  end

  @impl true
  def handle_info(:reload_equipments, socket) do
    {:noreply, load_equipments(socket)}
  end

  # --- ACTIONS FOR MODALS ---
  defp apply_action(socket, :new, _params), do: assign(socket, page_title: "Tambah Peralatan", equipment: %Equipment{})
  defp apply_action(socket, :edit, %{"id" => id}), do: assign(socket, page_title: "Kemaskini Peralatan", equipment: Assets.get_equipment!(id))
  defp apply_action(socket, :show, %{"id" => id}), do: assign(socket, page_title: "Lihat Peralatan", equipment: Assets.get_equipment!(id))
  defp apply_action(socket, :index, _params), do: assign(socket, page_title: "Senarai Peralatan", equipment: nil)

  @impl true
  def handle_params(params, _url, socket) do
    page   = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "q", "")
    status = Map.get(params, "status", "all")
    type = Map.get(params, "type", "all")
    {:noreply,
    socket
    |> assign(:page, page)
    |> assign(:search_query, search)
    |> assign(:filter_status, status)
    |> assign(:filter_type, type)
    |> load_equipments()
    |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="flex h-screen overflow-hidden">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
     <div class="flex flex-col flex-1">
      <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

      <main class="flex-1 overflow-y-auto pt-20 p-6 transition-all duration-300 bg-gray-100">
      <section class="mb-4">
          <h1 class="text-xl font-bold mb-1">Urus Peralatan</h1>
          <p class="text-md text-gray-500 mb-4">Semak dan urus semua peralatan dalam sistem</p>

          <!-- Stats Cards -->
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
            <%= for {label, value} <- [{"Jumlah Peralatan Berdaftar", @stats.total},
                                      {"Peralatan Tersedia", @stats.available},
                                      {"Dalam Penyelenggaraan", @stats.maintenance},
                                      {"Peralatan Aktif", @stats.active}] do %>

              <% number_color =
                case label do
                  "Jumlah Peralatan Berdaftar" -> "text-gray-700"
                  "Peralatan Tersedia" -> "text-green-500"
                  "Dalam Penyelenggaraan" -> "text-red-500"
                  "Peralatan Aktif" -> "text-blue-500"
                end %>

              <div class="bg-white p-4 rounded-xl shadow-md flex flex-col justify-between h-30 transition-transform hover:scale-105">
                <div>
                  <p class="text-sm text-gray-500"><%= label %></p>
                  <p class={"text-3xl font-bold mt-1 #{number_color}"}><%= value %></p>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Middle Section: Add Equipment Button -->
          <section class="mb-4 flex justify-end">
              <.link
                patch={~p"/admin/equipments/new"}
                style="background-color: #22376F; color: white;"
                class="inline-flex items-center justify-center rounded-md border border-transparent px-4 py-2 text-sm font-semibold hover:opacity-90"
              >
                Tambah Peralatan
              </.link>
          </section>

          <!-- Bottom Section: Equipment Table -->
          <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
          <!-- Header: Add + Search + Filter -->
          <div class="flex flex-col mb-4 gap-2">
            <div class="flex items-center justify-between">
              <h2 class="text-lg font-semibold text-gray-900">Senarai Peralatan</h2>
            </div>

            <!-- Search and Filter -->
            <div class="flex flex-wrap gap-2 mt-2">
              <form phx-change="search" class="flex-1 min-w-[200px]">
                <div class="relative">
                  <!-- Magnifying glass icon -->
                  <.icon name="hero-magnifying-glass" class="absolute left-2 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />

                  <!-- Input -->
                  <input type="text" name="q" value={@search_query} placeholder="Cari nama atau no. siri..." class="w-full border rounded-md pl-8 pr-2 py-1 text-sm"/>
                </div>
              </form>

              <!-- Filter by type -->
              <form phx-change="filter_type">
                <div class="relative">
                  <!-- Funnel icon -->
                  <.icon name="hero-funnel" class="absolute left-2 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />

                  <select name="type" class="border rounded-md pl-8 pr-8 py-1 text-sm">
                  <option value="all" selected={@filter_type in [nil, "all"]}>Semua Jenis</option>
                  <option value="laptop" selected={@filter_type == "laptop"}>Laptop / Notebook</option>
                  <option value="projector" selected={@filter_type == "projector"}>Projektor</option>
                  <option value="projector_screen" selected={@filter_type == "projector_screen"}>Projektor Screen</option>
                  <option value="printer" selected={@filter_type == "printer"}>Printer Mudah Alih</option>
                  <option value="kamera" selected={@filter_type == "kamera"}>Kamera</option>
                  <option value="speaker" selected={@filter_type == "speaker"}>Speaker</option>
                  <option value="laser_pointer" selected={@filter_type == "laser_pointer"}>Laser Pointer</option>
                  <option value="extension_cord" selected={@filter_type == "extension_cord"}>Extension Cord</option>
                  <option value="whiteboard" selected={@filter_type == "whiteboard"}>Whiteboard / Flipchart</option>
                  </select>
                </div>
              </form>

              <!-- Filter by status -->
              <form phx-change="filter_status">
                <div class="relative">
                  <!-- Funnel icon -->
                  <.icon name="hero-funnel" class="absolute left-2 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-500" />

                  <select name="status" class="border rounded-md pl-8 pr-8 py-1 text-sm">
                  <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                  <option value="tersedia" selected={@filter_status == "tersedia"}>Tersedia</option>
                  <option value="tidak_tersedia" selected={@filter_status == "tidak_tersedia"}>Tidak Tersedia</option>
                  </select>
                </div>
              </form>
            </div>
          </div>

          <!-- Equipments count message -->
          <div class="mb-2 text-sm text-gray-600">
            <%= if @filtered_count == 0 do %>
              Tiada peralatan ditemui
            <% else %>
              <%= @filtered_count %> peralatan ditemui
            <% end %>
          </div>

        <!-- Equipments Table -->
        <.table id="equipments" rows={@equipments_page} row_click={fn equipment ->
            JS.patch(
              ~p"/admin/equipments/#{equipment.id}?action=show&page=#{@page}&q=#{@search_query}&status=#{@filter_status}&type=#{@filter_type}"
            )
          end}>
          <:col :let={equipment} label="ID"><%= equipment.id %></:col>
          <:col :let={equipment} label="Peralatan">
              <div class="flex flex-col">
                <!-- Equipment Name -->
                <div class="font-semibold text-gray-900">
                  <%= equipment.name %>
                </div>

                <!-- Equipment Serial Number -->
                <div class="text-sm text-gray-500">
                  <%= equipment.serial_number %>
                </div>
              </div>
            </:col>
          <:col :let={equipment} label="Jenis">
            <!-- Equipment Type (colored pill badge) -->
                <div class="mt-1">
                  <%= case equipment.type do %>
                    <% "laptop" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Laptop / Notebook</span>
                    <% "projector" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-indigo-500">Projektor</span>
                    <% "projector_screen" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-black text-xs font-semibold bg-yellow-400">Projektor Screen</span>
                    <% "printer" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-green-500">Printer Mudah Alih</span>
                    <% "speaker" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-purple-600">Speaker</span>
                    <% "laser_pointer" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-red-500">Laser Pointer</span>
                    <% "extension_cord" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Extension Cord</span>
                    <% "whiteboard" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Whiteboard / Flipchart</span>
                    <% "kamera" -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-red-500">Kamera</span>
                    <% _ -> %>
                      <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Peralatan Lain</span>
                  <% end %>
              </div>
          </:col>
          <:col :let={equipment} label="Kuantiti Tersedia">{equipment.total_quantity} unit</:col>
          <:col :let={equipment} label="Ditambah Oleh">
              <%= equipment.created_by && equipment.created_by.user_profile && equipment.created_by.user_profile.full_name || "N/A" %>
          </:col>
          <:col :let={equipment} label="Tarikh & Masa Kemaskini">
              <%= Calendar.strftime(equipment.updated_at, "%d/%m/%Y %H:%M") %>
          </:col>
          <:col :let={equipment} label="Status">
          <span class={
            "px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
            case equipment.status do
              "tersedia" -> "bg-green-500"
              "tidak_tersedia" -> "bg-red-500"
              _ -> "bg-gray-400"
            end
          }>
            <%= Spato.Assets.Equipment.human_status(equipment.status) %>
          </span>
          </:col>
          <:action :let={equipment}>
              <.link patch={~p"/admin/equipments/#{equipment.id}/edit?page=#{@page}&q=#{@search_query}&status=#{@filter_status}&type=#{@filter_type}"}>Kemaskini</.link>
            </:action>
            <:action :let={equipment}>
              <.link phx-click={JS.push("delete", value: %{id: equipment.id}) |> hide("##{equipment.id}")} data-confirm="Padam peralatan?">Padam</.link>
            </:action>
          </.table>
          </section>

        <!-- Pagination -->
          <%= if @filtered_count > 0 do %>
          <div class="relative flex items-center mt-4">
            <!-- Previous button -->
            <div class="flex-1">
              <.link
                patch={~p"/admin/equipments?page=#{max(@page - 1, 1)}&q=#{@search_query}&status=#{@filter_status}&type=#{@filter_type}"}
                class={"px-3 py-1 border rounded #{if @page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
              >
                Sebelumnya
              </.link>
            </div>

            <!-- Page numbers (centered) -->
            <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
              <%= for p <- 1..@total_pages do %>
                <.link
                  patch={~p"/admin/equipments?page=#{p}&q=#{@search_query}&status=#{@filter_status}&type=#{@filter_type}"}
                  class={"px-3 py-1 border rounded #{if p == @page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
                >
                  <%= p %>
                </.link>
              <% end %>
            </div>

            <!-- Next button -->
            <div class="flex-1 text-right">
              <.link
                patch={~p"/admin/equipments?page=#{min(@page + 1, @total_pages)}&q=#{@search_query}&status=#{@filter_status}&type=#{@filter_type}"}
                class={"px-3 py-1 border rounded #{if @page == @total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
              >
                Seterusnya
              </.link>
            </div>
          </div>
          <% end %>

          <!-- Modals -->
          <.modal :if={@live_action in [:new, :edit]} id="equipment-modal" show on_cancel={JS.patch(~p"/admin/equipments?page=#{@page}&q=#{@search_query}&status=#{@filter_status}&type=#{@filter_type}")}>
          <.live_component
            module={SpatoWeb.EquipmentLive.FormComponent}
            id={@equipment.id || :new}
            title={@page_title}
            action={@live_action}
            equipment={@equipment}
            patch={~p"/admin/equipments?page=#{@page}&q=#{@search_query}&status=#{@filter_status}&type=#{@filter_type}"}
            current_user={@current_user}
            current_user_id={@current_user.id}
          />
        </.modal>

        <.modal :if={@live_action == :show} id="equipment-show-modal" show on_cancel={JS.patch(~p"/admin/equipments?page=#{@page}&q=#{@search_query}&status=#{@filter_status}&type=#{@filter_type}")}>
          <.live_component module={SpatoWeb.EquipmentLive.ShowComponent} id={@equipment.id} equipment={@equipment} />
        </.modal>
        </section>
      </main>
      </div>
    </div>
    """
  end
end

defmodule SpatoWeb.MeetingRoomLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Assets
  alias Spato.Assets.MeetingRoom

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Senarai Bilik Mesyuarat")
     |> assign(:active_tab, "manage_meeting_rooms")
     |> assign(:sidebar_open, true)
     |> assign(:filter_status, "all")
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:current_user, socket.assigns.current_user)
     |> stream(:meeting_rooms, Assets.list_meeting_rooms())}
  end

  defp load_meeting_rooms(socket) do
    params = %{
      "page" => socket.assigns.page,
      "search" => socket.assigns.search_query,
      "status" => socket.assigns.filter_status
    }

    data = Assets.list_meeting_rooms_paginated(params)

     # Global stats (not affected by filters)
      all_meeting_rooms = Assets.list_meeting_rooms()
      stats = %{
        total: length(all_meeting_rooms),
        available: Enum.count(all_meeting_rooms, &(&1.status == "tersedia")),
        maintenance: Enum.count(all_meeting_rooms, &(&1.status == "tidak_tersedia")),
        active: Enum.count(all_meeting_rooms, &(&1.status == "tersedia"))
      }

    socket
    |> assign(:meeting_rooms_page, data.meeting_rooms_page)
    |> assign(:total_pages, data.total_pages)
    |> assign(:stats, stats)
    |> assign(:filtered_count, data.total)
  end

  @impl true
  def handle_params(params, _url, socket) do
    page   = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "q", "")
    status = Map.get(params, "status", "all")

    {:noreply,
    socket
    |> assign(:page, page)
    |> assign(:search_query, search)
    |> assign(:filter_status, status)
    |> load_meeting_rooms()
    |> apply_action(socket.assigns.live_action, params)}
  end

 # --- ACTIONS FOR MODALS ---
 defp apply_action(socket, :new, _params), do: assign(socket, page_title: "Tambah Bilik Mesyuarat", meeting_room: %MeetingRoom{})
 defp apply_action(socket, :edit, %{"id" => id}), do: assign(socket, page_title: "Kemaskini Bilik Mesyuarat", meeting_room: Assets.get_meeting_room!(id))
 defp apply_action(socket, :show, %{"id" => id}), do: assign(socket, page_title: "Lihat Bilik Mesyuarat", meeting_room: Assets.get_meeting_room!(id))
 defp apply_action(socket, :index, _params), do: assign(socket, page_title: "Senarai Bilik Mesyuarat", meeting_room: nil)

  @impl true
  def handle_info({SpatoWeb.MeetingRoomLive.FormComponent, {:saved, _meeting_room}}, socket) do
    {:noreply, load_meeting_rooms(socket)}
  end

  @impl true
  def handle_info(:reload_meeting_rooms, socket) do
    {:noreply, load_meeting_rooms(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    meeting_room = Assets.get_meeting_room!(id)
    {:ok, _} = Assets.delete_meeting_room(meeting_room)
    {:noreply, load_meeting_rooms(socket)}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket), do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 1)
     |> load_meeting_rooms()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/admin/meeting_rooms?page=1&q=#{socket.assigns.search_query}&status=#{status}"
     )}
  end


  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, String.to_integer(page))
     |> load_meeting_rooms()}
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
            <h1 class="text-xl font-bold mb-1">Urus Bilik Mesyuarat</h1>
            <p class="text-md text-gray-500 mb-4">Semak dan urus semua bilik mesyuarat dalam sistem</p>

          <!-- Stats Cards -->
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
            <%= for {label, value} <- [{"Jumlah Bilik Mesyuarat Berdaftar", @stats.total},
                                      {"Bilik Mesyuarat Tersedia", @stats.available},
                                      {"Dalam Penyelenggaraan", @stats.maintenance},
                                      {"Bilik Mesyuarat Aktif", @stats.active}] do %>

              <% number_color =
                case label do
                  "Jumlah Bilik Mesyuarat Berdaftar" -> "text-gray-700"
                  "Bilik Mesyuarat Tersedia" -> "text-green-500"
                  "Dalam Penyelenggaraan" -> "text-red-500"
                  "Bilik Mesyuarat Aktif" -> "text-blue-500"
                end %>

              <div class="bg-white p-4 rounded-xl shadow-md flex flex-col justify-between h-30 transition-transform hover:scale-105">
                <div>
                  <p class="text-sm text-gray-500"><%= label %></p>
                  <p class={"text-3xl font-bold mt-1 #{number_color}"}><%= value %></p>
                </div>
              </div>
            <% end %>
          </div>

            <!-- Middle Section:Add Meeting Room Button -->
            <section class="mb-4 flex justify-end">
              <.link patch={~p"/admin/meeting_rooms/new"}>
                <.button class="bg-gray-900 text-white px-4 py-2 rounded-md hover:bg-gray-700">Tambah Bilik Mesyuarat</.button>
              </.link>
            </section>

            <!-- Bottom Section: Meeting Rooms Table -->
            <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
              <div class="flex flex-col mb-4 gap-2">
                <div class="flex items-center justify-between">
                  <h2 class="text-lg font-semibold text-gray-900">Senarai Bilik Mesyuarat</h2>
                </div>

              <!-- Search and Filter -->
              <div class="flex flex-wrap gap-2 mt-2">
              <form phx-change="search" class="flex-1 min-w-[200px]">
                <input type="text" name="q" value={@search_query} placeholder="Cari nama, lokasi atau kapasiti..." class="w-full border rounded-md px-2 py-1 text-sm"/>
              </form>

              <!-- Filter by status -->
              <form phx-change="filter_status">
                <select name="status" class="border rounded-md px-2 pr-8 py-1 text-sm">
                  <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                  <option value="tersedia" selected={@filter_status == "tersedia"}>Tersedia</option>
                  <option value="tidak_tersedia" selected={@filter_status == "tidak_tersedia"}>Tidak Tersedia</option>
                </select>
              </form>
            </div>
            </div>

          <!-- Equipments count message -->
          <div class="mb-2 text-sm text-gray-600">
            <%= if @filtered_count == 0 do %>
              Tiada bilik mesyuarat ditemui
            <% else %>
              <%= @filtered_count %> bilik mesyuarat ditemui
            <% end %>
          </div>

          <!-- Meeting Rooms Table -->
          <.table id="meeting_rooms" rows={@meeting_rooms_page} row_click={fn meeting_room ->
            JS.patch(
              ~p"/admin/meeting_rooms/#{meeting_room.id}?action=show&page=#{@page}&q=#{@search_query}&status=#{@filter_status}"
            )
          end}>
                <:col :let={meeting_room} label="ID"><%= meeting_room.id %></:col>
                <:col :let={meeting_room} label="Nama">{meeting_room.name}</:col>
                <:col :let={meeting_room} label="Lokasi">{meeting_room.location}</:col>
                <:col :let={meeting_room} label="Kapasiti">{meeting_room.capacity}</:col>
                <:col :let={meeting_room} label="Kemudahan Tersedia">{meeting_room.available_facility}</:col>
                <:col :let={meeting_room} label="Ditambah Oleh">
                  <%= meeting_room.created_by && meeting_room.created_by.user_profile && meeting_room.created_by.user_profile.full_name || "N/A" %>
                </:col>
                <:col :let={meeting_room} label="Tarikh & Masa Kemaskini">
              <%= Calendar.strftime(meeting_room.updated_at, "%d/%m/%Y %H:%M") %>
          </:col>
                <:col :let={meeting_room} label="Status">
                  <span class={
                    "px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
                    case meeting_room.status do
                      "tersedia" -> "bg-green-500"
                      "tidak_tersedia" -> "bg-red-500"
                      _ -> "bg-gray-400"
                    end
                  }>
                    <%= Spato.Assets.MeetingRoom.human_status(meeting_room.status) %>
                  </span>
                </:col>
                <:action :let={meeting_room}>
                  <div class="sr-only">
                    <.link navigate={~p"/admin/meeting_rooms/#{meeting_room.id}"}>Show</.link>
                  </div>
                  <.link patch={~p"/admin/meeting_rooms/#{meeting_room.id}/edit?page=#{@page}&q=#{@search_query}&status=#{@filter_status}"}>Kemaskini</.link>
                </:action>
                <:action :let={meeting_room}>
                  <.link
                    phx-click={JS.push("delete", value: %{id: meeting_room.id}) |> hide("##{meeting_room.id}")}
                    data-confirm="Padam bilik mesyuarat?"
                  >
                    Padam
                  </.link>
                </:action>
              </.table>
            </section>

        <!-- Pagination -->
          <%= if @filtered_count > 0 do %>
          <div class="relative flex items-center mt-4">
            <!-- Previous button -->
            <div class="flex-1">
              <.link
                patch={~p"/admin/meeting_rooms?page=#{max(@page - 1, 1)}&q=#{@search_query}&status=#{@filter_status}"}
                class={"px-3 py-1 border rounded #{if @page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
              >
                Sebelumnya
              </.link>
            </div>

            <!-- Page numbers (centered) -->
            <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
              <%= for p <- 1..@total_pages do %>
                <.link
                  patch={~p"/admin/meeting_rooms?page=#{p}&q=#{@search_query}&status=#{@filter_status}"}
                  class={"px-3 py-1 border rounded #{if p == @page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
                >
                  <%= p %>
                </.link>
              <% end %>
            </div>

            <!-- Next button -->
            <div class="flex-1 text-right">
              <.link
                patch={~p"/admin/meeting_rooms?page=#{min(@page + 1, @total_pages)}&q=#{@search_query}&status=#{@filter_status}"}
                class={"px-3 py-1 border rounded #{if @page == @total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
              >
                Seterusnya
              </.link>
            </div>
          </div>
          <% end %>

          <!-- Modals -->
          <.modal :if={@live_action in [:new, :edit]} id="meeting_room-modal" show on_cancel={JS.patch(~p"/admin/meeting_rooms?page=#{@page}&q=#{@search_query}&status=#{@filter_status}")}>
            <.live_component
              module={SpatoWeb.MeetingRoomLive.FormComponent}
              id={@meeting_room.id || :new}
              title={@page_title}
              action={@live_action}
              meeting_room={@meeting_room}
              current_user={@current_user}
              current_user_id={@current_user.id}
              patch={~p"/admin/meeting_rooms?page=#{@page}&q=#{@search_query}&status=#{@filter_status}"}
            />
          </.modal>

          <.modal :if={@live_action == :show} id="meeting_room-show-modal" show on_cancel={JS.patch(~p"/admin/meeting_rooms?page=#{@page}&q=#{@search_query}&status=#{@filter_status}")}>
            <.live_component module={SpatoWeb.MeetingRoomLive.ShowComponent}
            id={@meeting_room.id}
              meeting_room={@meeting_room}
            />
          </.modal>

          </section>
       </main>
      </div>
    </div>
    """
  end
end

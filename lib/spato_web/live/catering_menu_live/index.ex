defmodule SpatoWeb.CateringMenuLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Assets
  alias Spato.Assets.CateringMenu

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Senarai Menu Katering")
     |> assign(:active_tab, "manage_catering")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:filter_status, "all")
     |> assign(:filter_type, "all")
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> stream(:catering_menus, Assets.list_catering_menus())}
  end

  # --- LOAD CATERING MENUS ---
  defp load_catering_menus(socket) do
    params = %{
      "page" => socket.assigns.page,
      "search" => socket.assigns.search_query,
      "status" => socket.assigns.filter_status,
      "type" => socket.assigns.filter_type
    }

    data = Assets.list_catering_menus_paginated(params)

    all_menus = Assets.list_catering_menus()
    stats = %{
      total: length(all_menus),
      active: Enum.count(all_menus, &(&1.status == "tersedia")),
      inactive: Enum.count(all_menus, &(&1.status == "tidak_tersedia"))
    }

    socket
    |> assign(:catering_menus_page, data.catering_menus_page)
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
     |> load_catering_menus()}
  end


  @impl true
  def handle_event("filter_type", %{"type" => type}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/admin/catering_menus?page=1&q=#{socket.assigns.search_query}&status=#{socket.assigns.filter_status}&type=#{type}"
     )}
  end



  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, String.to_integer(page))
     |> load_catering_menus()}
  end

  @impl true
  def handle_event("toggle_sidebar", _, socket), do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    catering_menu = Assets.get_catering_menu!(id)
    {:ok, _} = Assets.delete_catering_menu(catering_menu)
    {:noreply, load_catering_menus(socket)}
  end

  @impl true
  def handle_info({SpatoWeb.CateringMenuLive.FormComponent, {:saved, _menu}}, socket) do
    {:noreply, load_catering_menus(socket)}
  end

  @impl true
  def handle_info(:reload_catering_menus, socket) do
    {:noreply, load_catering_menus(socket)}
  end

  # --- ACTIONS FOR MODALS ---
  defp apply_action(socket, :new, _params), do: assign(socket, page_title: "Tambah Menu Katering", catering_menu: %CateringMenu{})
  defp apply_action(socket, :edit, %{"id" => id}), do: assign(socket, page_title: "Kemaskini Menu Katering", catering_menu: Assets.get_catering_menu!(id))
  defp apply_action(socket, :show, %{"id" => id}), do: assign(socket, page_title: "Lihat Menu Katering", catering_menu: Assets.get_catering_menu!(id))
  defp apply_action(socket, :index, _params), do: assign(socket, page_title: "Senarai Menu Katering", catering_menu: nil)

  @impl true
  def handle_params(params, _url, socket) do
    page   = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "q", "")
    type   = Map.get(params, "type", "all")

    {:noreply,
    socket
    |> assign(:page, page)
    |> assign(:search_query, search)
    |> assign(:filter_type, type)
    |> load_catering_menus()
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
          <h1 class="text-xl font-bold mb-1">Urus Menu Katering</h1>
          <p class="text-md text-gray-500 mb-4">Semak dan urus semua menu katering dalam sistem</p>

          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-4">
            <%= for {label, value} <- [{"Jumlah Menu", @stats.total},
                                      {"Aktif", @stats.active},
                                      {"Tidak Aktif", @stats.inactive}] do %>

              <% number_color =
                case label do
                  "Jumlah Menu" -> "text-gray-700"
                  "Aktif" -> "text-green-500"
                  "Tidak Aktif" -> "text-red-500"
                end %>

              <div class="bg-white p-4 rounded-xl shadow-md flex flex-col justify-between h-30 transition-transform hover:scale-105">
                <div>
                  <p class="text-sm text-gray-500"><%= label %></p>
                  <p class={"text-3xl font-bold mt-1 #{number_color}"}><%= value %></p>
                </div>
              </div>
            <% end %>
          </div>

        <section class="mb-4 flex justify-end">
          <.link patch={~p"/admin/catering_menus/new"}>
                <.button class="bg-gray-900 text-white px-4 py-2 rounded-md hover:bg-gray-700">Tambah Menu</.button>
              </.link>
        </section>

          <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
          <div class="flex flex-col mb-4 gap-2">
            <div class="flex items-center justify-between">
              <h2 class="text-lg font-semibold text-gray-900">Senarai Menu Katering</h2>
            </div>

            <div class="flex flex-wrap gap-2 mt-2">
              <form phx-change="search" class="flex-1 min-w-[200px]">
                <input type="text" name="q" value={@search_query} placeholder="Cari nama atau keterangan..." class="w-full border rounded-md px-2 py-1 text-sm"/>
              </form>

             <form phx-change="filter_type">
              <select name="type" class="border rounded-md px-2 pr-8 py-1 text-sm">
                <option value="all" selected={@filter_type in [nil, "all"]}>Semua Jenis</option>
                <option value="sarapan" selected={@filter_type == "sarapan"}>Sarapan</option>
                <option value="makan_tengahari" selected={@filter_type == "makan_tengahari"}>Makan Tengahari</option>
                <option value="minum_petang" selected={@filter_type == "minum_petang"}>Minum Petang</option>
              </select>
            </form>

            </div>
          </div>

          <div class="mb-2 text-sm text-gray-600">
            <%= if @filtered_count == 0 do %>
              Tiada menu ditemui
            <% else %>
              <%= @filtered_count %> menu ditemui
            <% end %>
          </div>

        <.table id="catering_menus" rows={@catering_menus_page} row_click={fn menu ->
            JS.patch(
              ~p"/admin/catering_menus/#{menu.id}?action=show&page=#{@page}&q=#{@search_query}&status=#{@filter_status}"
            )
          end}>
          <:col :let={menu} label="ID"><%= menu.id %></:col>
          <:col :let={menu} label="Nama"><%= menu.name %></:col>
          <:col :let={menu} label="Harga/Seorang">RM <%= menu.price_per_head %></:col>
          <:col :let={menu} label="Jenis">
          <span class="px-1.5 py-0.5 rounded-md text-gray-700 text-xs font-medium bg-gray-100">
            <%= Spato.Assets.CateringMenu.human_type(menu.type) %>
          </span>
          </:col>
          <:col :let={menu} label="Ditambah Oleh">
            <%= if menu.created_by do %>
              <%= Spato.Accounts.User.display_name(menu.created_by) %>
            <% else %>
              -
            <% end %>
          </:col>
          <:col :let={menu} label="Tarikh & Masa Ditambah">
            <%= if menu.inserted_at do %>
              <%= Calendar.strftime(menu.inserted_at, "%d/%m/%Y %H:%M") %>
            <% else %>
              -
            <% end %>
          </:col>
          <:action :let={menu}>
              <.link patch={~p"/admin/catering_menus/#{menu.id}/edit"}>Kemaskini</.link>
            </:action>
            <:action :let={menu}>
              <.link phx-click={JS.push("delete", value: %{id: menu.id}) |> hide("##{menu.id}")} data-confirm="Padam menu?">Padam</.link>
            </:action>
          </.table>
          </section>

          <%= if @filtered_count > 0 do %>
          <div class="relative flex items-center mt-4">
            <div class="flex-1">
              <.link
                patch={~p"/admin/catering_menus?page=#{max(@page - 1, 1)}&q=#{@search_query}&status=#{@filter_status}"}
                class={"px-3 py-1 border rounded #{if @page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
              >
                Sebelumnya
              </.link>
            </div>

            <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
              <%= for p <- 1..@total_pages do %>
                <.link
                  patch={~p"/admin/catering_menus?page=#{p}&q=#{@search_query}&status=#{@filter_status}"}
                  class={"px-3 py-1 border rounded #{if p == @page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
                >
                  <%= p %>
                </.link>
              <% end %>
            </div>

            <div class="flex-1 text-right">
              <.link
                patch={~p"/admin/catering_menus?page=#{min(@page + 1, @total_pages)}&q=#{@search_query}&status=#{@filter_status}"}
                class={"px-3 py-1 border rounded #{if @page == @total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
              >
                Seterusnya
              </.link>
            </div>
          </div>
          <% end %>

          <.modal :if={@live_action in [:new, :edit]} id="catering-menu-modal" show on_cancel={JS.patch(~p"/admin/catering_menus")}>
          <.live_component
            module={SpatoWeb.CateringMenuLive.FormComponent}
            id={@catering_menu.id || :new}
            title={@page_title}
            action={@live_action}
            catering_menu={@catering_menu}
            patch={~p"/admin/catering_menus"}
            current_user={@current_user}
            current_user_id={@current_user.id}
          />
        </.modal>

        <.modal :if={@live_action == :show} id="catering-menu-show-modal" show on_cancel={JS.patch(~p"/admin/catering_menus?page=#{@page}&q=#{@search_query}&status=#{@filter_status}")}>
          <.live_component module={SpatoWeb.CateringMenuLive.ShowComponent} id={@catering_menu.id} catering_menu={@catering_menu} />
        </.modal>
        </section>
      </main>
      </div>
    </div>
    """
  end
end

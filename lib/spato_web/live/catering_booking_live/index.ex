defmodule SpatoWeb.CateringBookingLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Bookings
  alias Spato.Bookings.CateringBooking

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, "catering")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:filter_status, "all")
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:filter_date, "")
     |> assign(:catering_booking, nil)
     |> assign(:menus, [])
     |> assign(:params, %{})
     |> assign(:show_cancel_modal, false)
     |> assign(:cancel_booking, nil)
     |> assign(:stats, Bookings.get_user_catering_booking_stats(socket.assigns.current_user.id))
     |> load_catering_bookings()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page   = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "q", "")
    status = Map.get(params, "status", "all")
    date   = Map.get(params, "date", "")

    socket =
      socket
      |> assign(:page, page)
      |> assign(:search_query, search)
      |> assign(:filter_status, status)
      |> assign(:filter_date, date)
      |> load_catering_bookings()

    socket =
      case socket.assigns.live_action do
        :edit ->
          id = Map.get(params, "id")
          booking = Bookings.get_catering_booking!(id)

          if booking.status == "pending" and booking.user_id == socket.assigns.current_user.id do
            apply_action(socket, :edit, params)
          else
            socket
            |> put_flash(:error, "Anda tidak boleh mengemaskini tempahan ini.")
            |> push_patch(to: ~p"/catering_bookings")
          end

        action ->
          apply_action(socket, action, params)
      end

    {:noreply, socket}
  end

  # --- APPLY ACTIONS ---

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Senarai Tempahan Katering")
    |> assign(:catering_booking, nil)
    |> assign(:params, %{})
  end

  defp apply_action(socket, :new, params) do
    socket
    |> assign(:page_title, "Tambah Tempahan Katering")
    |> assign(:catering_booking, %CateringBooking{})
    |> assign(:params, params)
  end

  defp apply_action(socket, :edit, %{"id" => id} = params) do
    socket
    |> assign(:page_title, "Kemaskini Tempahan Katering")
    |> assign(:catering_booking, Bookings.get_catering_booking!(id))
    |> assign(:params, params)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Tempahan Katering")
    |> assign(:catering_booking, Bookings.get_catering_booking!(id))
  end

  # --- LOAD BOOKINGS ---

  defp load_catering_bookings(socket) do
    params = %{
      "page" => socket.assigns.page,
      "search" => socket.assigns.search_query,
      "status" => socket.assigns.filter_status,
      "date" => socket.assigns.filter_date
    }

    data = Bookings.list_catering_bookings_paginated(params, socket.assigns.current_user)

    socket
    |> assign(:catering_bookings_page, data.catering_bookings_page)
    |> assign(:total_pages, data.total_pages)
    |> assign(:filtered_count, data.total)
    |> assign(:stats, Bookings.get_user_catering_booking_stats(socket.assigns.current_user.id))
    |> assign(:page, data.page)
  end

  # --- HANDLE EVENTS ---

  @impl true
  def handle_info({SpatoWeb.CateringBookingLive.FormComponent, {:saved, _catering_booking}}, socket) do
    {:noreply, load_catering_bookings(socket)}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 1)
     |> load_catering_bookings()}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/catering_bookings?page=1&q=#{socket.assigns.search_query}&status=#{status}"
     )}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, String.to_integer(page))
     |> load_catering_bookings()}
  end

  @impl true
  def handle_event("filter_date", %{"date" => date}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/catering_bookings?page=1&q=#{socket.assigns.search_query}&status=#{socket.assigns.filter_status}&date=#{date}"
     )}
  end

  @impl true
  def handle_event("cancel", %{"id" => id}, socket) do
    booking = Bookings.get_catering_booking!(id)

    case Bookings.cancel_catering_booking(booking, socket.assigns.current_user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> load_catering_bookings()
         |> assign(:stats, Bookings.get_user_catering_booking_stats(socket.assigns.current_user.id))}

      {:error, :not_allowed} ->
        {:noreply, socket |> put_flash(:error, "Tidak boleh batal selepas tindakan admin.")}
    end
  end

  # open modal
  def handle_event("open_cancel_modal", %{"id" => id}, socket) do
    booking = Bookings.get_catering_booking!(id)
    {:noreply,
     socket
     |> assign(:cancel_booking, booking)
     |> assign(:show_cancel_modal, true)}
  end

  # submit cancellation
  def handle_event("submit_cancel", %{"reason" => reason}, socket) do
    booking = socket.assigns.cancel_booking
    user = socket.assigns.current_user

    case Bookings.cancel_catering_booking(booking, user, reason) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:show_cancel_modal, false)
         |> load_catering_bookings()
         |> assign(:stats, Bookings.get_user_catering_booking_stats(user.id))}

      {:error, :not_allowed} ->
        {:noreply,
         socket
         |> assign(:show_cancel_modal, false)
         |> put_flash(:error, "Tidak boleh batal tempahan ini.")}
    end
  end

  # close modal
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_cancel_modal, false)}
  end

  # --- RENDER ---

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
      <div class="flex flex-col flex-1">
        <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

        <main class="flex-1 overflow-y-auto pt-20 p-6 transition-all duration-300 bg-gray-100">
          <section class="mb-4">
            <h1 class="text-xl font-bold mb-1">Tempahan Katering Saya</h1>
            <p class="text-md text-gray-500 mb-4">Semak semua tempahan katering yang anda buat</p>

            <!-- Stats Cards for Current User -->
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
              <%= for {label, value, color} <- [
                    {"Jumlah Tempahan Minggu Ini", @stats.total, "text-gray-700"},
                    {"Menunggu", @stats.pending, "text-yellow-500"},
                    {"Diluluskan", @stats.approved, "text-green-500"},
                    {"Selesai", @stats.completed, "text-blue-500"}
                  ] do %>

                <div class="bg-white p-4 rounded-xl shadow-md flex flex-col justify-between h-30 transition-transform hover:scale-105">
                  <div>
                    <p class="text-sm text-gray-500"><%= label %></p>
                    <p class={"text-3xl font-bold mt-1 #{color}"}><%= value %></p>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Middle Section: Add Catering Button -->
            <section class="mb-4 flex justify-end">
              <.link patch={~p"/available_catering"}>
                    <.button class="bg-gray-900 text-white px-4 py-2 rounded-md hover:bg-gray-700">Tempah Katering</.button>
                  </.link>
            </section>

            <!-- Booking Table Section -->
            <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
              <div class="flex flex-col mb-4 gap-2">
                <div class="flex items-center justify-between">
                  <h2 class="text-lg font-semibold text-gray-900">Senarai Tempahan Katering</h2>
                </div>

                <div class="flex flex-wrap gap-2 mt-2">
                  <!-- Search -->
                  <form phx-change="search" class="flex-1 min-w-[200px]">
                    <input type="text" name="q" value={@search_query} placeholder="Cari lokasi, permintaan khusus..." class="w-full border rounded-md px-2 py-1 text-sm"/>
                  </form>

                  <!-- Status filter -->
                  <form phx-change="filter_status">
                    <select name="status" class="border rounded-md px-2 pr-8 py-1 text-sm">
                      <option value="all" selected={@filter_status in [nil, "all"]}>Semua Status</option>
                      <option value="pending" selected={@filter_status == "pending"}>Menunggu</option>
                      <option value="approved" selected={@filter_status == "approved"}>Diluluskan</option>
                      <option value="rejected" selected={@filter_status == "rejected"}>Ditolak</option>
                      <option value="completed" selected={@filter_status == "completed"}>Selesai</option>
                    </select>
                  </form>

                  <!-- Date filter -->
                  <form phx-change="filter_date">
                    <input type="date" name="date" value={@filter_date} class="border rounded-md px-2 py-1 text-sm"/>
                  </form>
                </div>
              </div>

              <div class="mb-2 text-sm text-gray-600">
                <%= if @filtered_count == 0 do %>
                  Tiada tempahan ditemui
                <% else %>
                  <%= @filtered_count %> tempahan ditemui
                <% end %>
              </div>

              <.table
                id="catering_bookings"
                rows={@catering_bookings_page}
                row_click={fn booking ->
                  JS.patch(~p"/catering_bookings/#{booking.id}?action=show&page=#{@page}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}")
                end}
              >
                <:col :let={booking} label="ID"><%= booking.id %></:col>

                <:col :let={booking} label="Menu">
                  <%= if booking.menu do %>
                    <div class="flex flex-col">
                      <div class="font-semibold text-gray-900">
                        <%= booking.menu.name %>
                      </div>
                      <div class="text-sm text-gray-500">
                        <%= booking.menu.description %>
                      </div>
                      <div class="mt-1">
                        <%= case booking.menu.type do %>
                          <% "all" -> %>
                            <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-gray-400">Semua</span>
                          <% "sarapan" -> %>
                            <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Sarapan</span>
                          <% "makan_tengahari" -> %>
                            <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-indigo-500">Makan Tengahari</span>
                          <% "minum_petang" -> %>
                            <span class="px-1.5 py-0.5 rounded-full text-black text-xs font-semibold bg-yellow-400">Minum Petang</span>
                          <% "minum_malam" -> %>
                            <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-red-500">Minum Malam</span>
                          <% "makan_malam" -> %>
                            <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-green-500">Makan Malam</span>
                          <% "minum_pagi" -> %>
                            <span class="px-1.5 py-0.5 rounded-full text-white text-xs font-semibold bg-blue-500">Minum Pagi</span>
                        <% end %>
                      </div>
                    </div>
                  <% else %>
                    <span class="text-gray-400">—</span>
                  <% end %>
                </:col>

                <:col :let={booking} label="Tarikh & Masa">
                  <div class="flex flex-col">
                    <span class="font-medium text-gray-900">
                      <%= Calendar.strftime(booking.date, "%d-%m-%Y") %>
                    </span>
                    <span class="text-sm text-gray-500">
                      <%= Calendar.strftime(booking.time, "%H:%M") %>
                    </span>
                  </div>
                </:col>

                <:col :let={booking} label="Lokasi & Peserta">
                  <div class="flex flex-col">
                    <span class="font-medium text-gray-900"><%= booking.location %></span>
                    <span class="text-sm text-gray-500"><%= booking.participants %> orang</span>
                  </div>
                </:col>

                <:col :let={booking} label="Jumlah Kos">
                  <div class="font-medium text-gray-900">
                    <%= if booking.total_cost do %>
                      <%= Spato.Bookings.format_money(booking.total_cost) %>
                    <% else %>
                      RM 0.00
                    <% end %>
                  </div>
                </:col>


                <:col :let={booking} label="Permintaan Khusus">{booking.special_request}</:col>

                <:col :let={booking} label="Status">
                  <span class={"px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
                    case booking.status do
                      "pending" -> "bg-yellow-500"
                      "approved" -> "bg-green-500"
                      "rejected" -> "bg-red-500"
                      "completed" -> "bg-blue-500"
                      "cancelled" -> "bg-gray-400"
                      _ -> "bg-gray-400"
                    end}>
                    <%= Spato.Bookings.CateringBooking.human_status(booking.status) %>
                  </span>
                </:col>

              <:action :let={booking}>
                <div class="flex gap-2">
                  <%= if booking.status == "pending" do %>
                    <.link
                      patch={~p"/catering_bookings/#{booking.id}/edit?page=#{@page}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                      class="flex items-center justify-center w-8 h-8 rounded-full bg-blue-600 hover:bg-blue-700 text-white transition-colors"
                      title="Kemaskini Tempahan"
                    >
                      <.icon name="hero-pencil-square" class="w-4 h-4" />
                    </.link>
                  <% end %>

                  <%= if booking.status in ["pending", "approved"] do %>
                    <button
                      phx-click="open_cancel_modal"
                      phx-value-id={booking.id}
                      class="flex items-center justify-center w-8 h-8 rounded-full bg-red-600 hover:bg-red-700 text-white transition-colors"
                      title="Batalkan Tempahan"
                    >
                      <.icon name="hero-x-mark" class="w-4 h-4" />
                    </button>
                  <% end %>
                </div>
              </:action>
              </.table>

              <!-- Pagination -->
              <%= if @filtered_count > 1 do %>
                <div class="relative flex items-center mt-4">
                  <!-- Previous -->
                  <div class="flex-1">
                    <.link
                      patch={~p"/catering_bookings?page=#{max(@page - 1, 1)}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                      class={"px-3 py-1 border rounded " <>
                        if @page == 1,
                          do: "bg-gray-200 text-gray-500 cursor-not-allowed",
                          else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Sebelumnya
                    </.link>
                  </div>

                  <!-- Page numbers -->
                  <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
                    <%= for p <- 1..@total_pages do %>
                      <.link
                        patch={~p"/catering_bookings?page=#{p}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                        class={"px-3 py-1 border rounded " <>
                          if p == @page,
                            do: "bg-gray-700 text-white",
                            else: "bg-white text-gray-700 hover:bg-gray-100"}>
                        <%= p %>
                      </.link>
                    <% end %>
                  </div>

                  <!-- Next -->
                  <div class="flex-1 text-right">
                    <.link
                      patch={~p"/catering_bookings?page=#{min(@page + 1, @total_pages)}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                      class={"px-3 py-1 border rounded " <>
                        if @page == @total_pages,
                          do: "bg-gray-200 text-gray-500 cursor-not-allowed",
                          else: "bg-white text-gray-700 hover:bg-gray-100"}>
                      Seterusnya
                    </.link>
                  </div>
                </div>
              <% end %>


              <.modal
                  :if={@live_action in [:new, :edit]}
                  id="catering-booking-form-modal"
                  show
                  on_cancel={JS.patch(~p"/catering_bookings?page=#{@page}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}")}>
                  <.live_component
                    module={SpatoWeb.CateringBookingLive.FormComponent}
                    id={@catering_booking.id || :new}
                    title={@page_title}
                    action={@live_action}
                    catering_booking={@catering_booking}
                    current_user={@current_user}
                    patch={~p"/catering_bookings?page=#{@page}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}"}
                    params={@params}
                  />
                </.modal>

              <!-- Modal for show -->
              <.modal
                :if={@live_action == :show}
                id="catering-booking-show-modal"
                show
                on_cancel={JS.patch(~p"/catering_bookings?page=#{@page}&q=#{@search_query}&status=#{@filter_status}&date=#{@filter_date}")}>
                <.live_component
                  module={SpatoWeb.CateringBookingLive.ShowComponent}
                  id={@catering_booking.id}
                  catering_booking={@catering_booking}
                  current_user={@current_user}
                />
              </.modal>

              <!-- Cancel modal -->
              <.modal :if={@show_cancel_modal} id="cancel-catering-modal" show on_cancel={JS.push("close_modal")}>
                <h2 class="text-lg font-semibold mb-2">Sebab Pembatalan</h2>
                <form phx-submit="submit_cancel" class="space-y-3">
                  <textarea name="reason" rows="3" class="w-full border rounded-md p-2 text-sm" placeholder="Nyatakan sebab pembatalan..."></textarea>
                  <div class="flex justify-end gap-2">
                    <button type="button" phx-click="close_modal" class="px-3 py-1 border rounded-md">Batal</button>
                    <button type="submit" class="px-3 py-1 bg-red-600 text-white rounded-md">Hantar</button>
                  </div>
                </form>
              </.modal>
            </section>
          </section>
        </main>
      </div>
    </div>
    """
  end
end

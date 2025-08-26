defmodule SpatoWeb.UserProfileLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Accounts
  alias Spato.Accounts.UserProfile
  alias SpatoWeb.UserRegistrationLive.FormComponent

  @per_page 10
  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.list_user_profiles()
    stats = Accounts.user_stats()

    registration_changeset = Accounts.change_user_registration(%Accounts.User{})

    socket =
      socket
      |> assign(:page_title, "Senarai Pengguna")
      |> assign(:active_tab, "user_profiles")
      |> assign(:sidebar_open, true)
      |> assign(:current_user, socket.assigns.current_user)
      |> assign(:stats, stats)
      |> assign(:show_registration_modal, false)
      |> assign(:form, to_form(registration_changeset, as: "user"))
      |> assign(:roles, [{"Admin", "admin"}, {"User", "user"}])
      |> assign(:check_errors, false)
      |> assign(:filter_role, "all")
      |> assign(:search_query, "")
      |> assign(:users, users)
      |> assign(:page, 1)
      |> assign_pagination()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()

    socket =
      socket
      |> assign(:page, page)
      |> update_filtered_users()
      |> assign_pagination()
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
  end

  # Modal show action
  defp apply_action(socket, :show, %{"id" => id}) do
    user = Accounts.get_user_with_profile!(id)

    assign(socket,
      page_title: "Lihat Pengguna",
      user: user,
      user_profile: user.user_profile
    )
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, page_title: "Senarai Pengguna", user_profile: nil)
  end

  # Handle saves from UserRegistration form
  @impl true
  def handle_info({FormComponent, {:saved, user}}, socket) do
    # Load the user with their profile before streaming
    user_with_profile = Accounts.get_user_with_profile!(user.id)

    users = [user_with_profile | socket.assigns.users]

    {:noreply,
     socket
     |> assign(:users, users)
     |> assign_pagination()
     |> put_flash(:info, "Pengguna berjaya didaftarkan!")
     |> assign(show_registration_modal: false, check_errors: false)}
  end



  # Sidebar toggle
  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  # Show/hide registration modal
  def handle_event("show_registration_modal", _, socket) do
    {:noreply, assign(socket, show_registration_modal: true)}
  end

  def handle_event("hide_registration_modal", _, socket) do
    {:noreply, assign(socket, show_registration_modal: false, check_errors: false)}
  end

  # Delete user
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user_with_profile!(id)

    case Accounts.delete_user(user) do
      {:ok, _} ->
        users = Enum.reject(socket.assigns.users, fn u -> u.id == user.id end)
        {:noreply, socket |> assign(:users, users) |> assign_pagination()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Tidak boleh padam pengguna")}
    end
  end

  # Filter & search events
  @impl true
  def handle_event("filter_role", %{"role" => role}, socket) do
    socket =
      socket
      |> assign(:filter_role, role)
      |> assign(:page, 1)
      |> update_filtered_users()
      |> assign_pagination()

    {:noreply, socket}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    socket =
      socket
      |> assign(:search_query, query)
      |> assign(:page, 1)
      |> update_filtered_users()
      |> assign_pagination()

    {:noreply, socket}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    page = String.to_integer(page)

    socket =
      socket
      |> assign(:page, page)
      |> assign(:users_page, paginated_users(socket.assigns.users, page))

    {:noreply, push_patch(socket, to: ~p"/admin/user_profiles?page=#{page}")}
  end

  # --- Helpers ---
  defp update_filtered_users(socket) do
    filtered =
      Accounts.list_user_profiles()
      |> Enum.filter(fn u ->
        role_ok = socket.assigns.filter_role == "all" or (u.role || "") == socket.assigns.filter_role

        query = String.downcase(socket.assigns.search_query || "")
        query_ok =
          query == "" or
            String.contains?(String.downcase(u.email || ""), query) or
            (u.user_profile && String.contains?(String.downcase(u.user_profile.full_name || ""), query)) or
            (u.user_profile && String.contains?(String.downcase(u.user_profile.position || ""), query)) or
            (u.user_profile && u.user_profile.department && String.contains?(String.downcase(u.user_profile.department.name || ""), query))

        role_ok and query_ok
      end)

    assign(socket, :users, filtered)
  end

  defp paginated_users(users, page) do
    users
    |> Enum.chunk_every(@per_page)
    |> Enum.at(page - 1, [])
  end

  defp total_pages(users) do
    (Enum.count(users) / @per_page) |> Float.ceil() |> trunc()
  end

  defp assign_pagination(socket) do
    users_page = paginated_users(socket.assigns.users, socket.assigns.page)
    total_pages = total_pages(socket.assigns.users)
    assign(socket, users_page: users_page, total_pages: total_pages)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden">

    <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
    <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

      <main class="flex-1 pt-16 p-6 transition-all duration-300 overflow-y-auto">
        <div class="bg-gray-100 p-4 md:p-8 rounded-lg">
          <h1 class="text-xl font-bold mb-1">Senarai Pengguna</h1>
          <p class="text-md text-gray-500 mb-6">Semak semua pengguna dalam sistem</p>

         <!-- Stats Cards -->
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <%= for {label, value} <- [{"Jumlah Pengguna", @stats.total_users}, {"Admin", @stats.admins}, {"Staf", @stats.users}, {"Aktif 30 Hari", @stats.active_users}] do %>
              <div class="bg-white p-4 rounded-xl shadow-md flex flex-col justify-between h-30 transition-transform hover:scale-105">
                <div>
                  <p class="text-sm text-gray-500"><%= label %></p>
                  <p class="text-3xl font-bold mt-1"><%= value %></p>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Header: Search + Add + Filter -->
          <div class="flex items-center justify-between mb-4 space-x-2">
            <h2 class="text-lg font-semibold text-gray-900">Senarai Profil Pengguna</h2>

            <form phx-change="search">
              <input type="text" name="q" value={@search_query} placeholder="Cari nama, emel, jabatan..." class="border rounded-md px-2 py-1 text-sm"/>
            </form>

            <.button
              phx-click="show_registration_modal"
              class="inline-flex items-center justify-center rounded-md border border-transparent bg-gray-900 px-4 py-2 text-sm font-semibold text-white hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-800 focus:ring-offset-2"
            >
              Tambah Pengguna
            </.button>

            <form phx-change="filter_role" class="inline-block">
              <select name="role" class="border rounded-md px-2 py-1 text-sm">
                <option value="all" selected={@filter_role in [nil, "all"]}>Semua Peranan</option>
                <option value="admin" selected={@filter_role == "admin"}>Admin</option>
                <option value="user" selected={@filter_role == "user"}>User</option>
              </select>
            </form>
          </div>

          <!-- Table -->
          <.table
            id="user_profiles"
            rows={@users_page}
            row_click={fn u -> JS.patch(~p"/admin/user_profiles/#{u.id}?action=show") end}
          >
            <:col :let={u} label="Nama Penuh"><%= if u.user_profile && Map.has_key?(u.user_profile, :full_name), do: u.user_profile.full_name, else: "Belum diisi" %></:col>
            <:col :let={u} label="Emel"><%= u.email %></:col>
            <:col :let={u} label="Jabatan"><%= if u.user_profile && u.user_profile.department && Map.has_key?(u.user_profile.department, :name), do: u.user_profile.department.name, else: "Belum diisi" %></:col>
            <:col :let={u} label="Jawatan"><%= if u.user_profile && Map.has_key?(u.user_profile, :position), do: u.user_profile.position, else: "Belum diisi" %></:col>
            <:col :let={u} label="Status Pekerjaan"><%= if u.user_profile && u.user_profile.employment_status, do: UserProfile.human_employment_status(u.user_profile.employment_status), else: "Belum diisi" %></:col>
            <:col :let={u} label="Jantina"><%= if u.user_profile && u.user_profile.gender, do: UserProfile.human_gender(u.user_profile.gender), else: "Belum diisi" %></:col>
            <:col :let={u} label="No. Telefon"><%= if u.user_profile && Map.has_key?(u.user_profile, :phone_number), do: u.user_profile.phone_number, else: "Belum diisi" %></:col>
            <:col :let={u} label="Alamat"><%= if u.user_profile && Map.has_key?(u.user_profile, :address), do: u.user_profile.address, else: "Belum diisi" %></:col>
            <:col :let={u} label="Peranan"><%= u.role || "Belum diisi" %></:col>

            <:action :let={u}>
              <.link phx-click={JS.push("delete", value: %{id: u.id}) |> hide("##{u.id}")} data-confirm="Anda yakin?">Delete</.link>
            </:action>
          </.table>

          <!-- Pagination -->
          <div class="flex space-x-1 mt-4">
            <%= for p <- 1..@total_pages do %>
              <.link patch={~p"/admin/user_profiles?page=#{p}"} class={"px-3 py-1 border rounded #{if p == @page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700"}"}>
                <%= p %>
              </.link>
            <% end %>
          </div>

          <!-- Show Modal -->
          <.modal :if={@live_action == :show} id="user-profile-show-modal" show on_cancel={JS.patch(~p"/admin/user_profiles")}>
            <.live_component
              module={SpatoWeb.UserProfileLive.ShowComponent}
              id={@user.id}
              title={@page_title}
              user={@user}
              user_profile={@user_profile}
            />
          </.modal>

          <!-- Registration Modal -->
          <.modal :if={@show_registration_modal} id="new-user-modal" show on_cancel={JS.push("hide_registration_modal")}>
           <.live_component
            module={FormComponent}
            id="new-user"
            title="Daftar Pengguna Baru"
            action={:new}
            user={%Accounts.User{}}
            patch={~p"/admin/user_profiles"}
            form={@form}
            roles={@roles}
            check_errors={@check_errors}
          />
          </.modal>
        </div>
      </main>
    </div>
    """
  end
end

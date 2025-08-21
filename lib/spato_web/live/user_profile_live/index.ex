defmodule SpatoWeb.UserProfileLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar

  alias Spato.Accounts
  alias Spato.Accounts.UserProfile

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    user_profiles = Accounts.list_user_profiles()
    stats = Accounts.user_stats()

    {:ok,
      socket
      |> assign(:page_title, "Senarai Pengguna")
      |> assign(:active_tab, "user_profiles")
      |> assign(:sidebar_open, true)
      |> assign(:current_user, socket.assigns.current_user)
      |> assign(:stats, stats)
      |> stream(:user_profiles, user_profiles)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # Modal show action
  defp apply_action(socket, :show, %{"id" => id}) do
    user_profile = Accounts.get_user_profile!(id) # preload inside context
    assign(socket, page_title: "Lihat Profil Pengguna", user_profile: user_profile)
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, page_title: "Senarai Pengguna", user_profile: nil)
  end

  # Sidebar toggle
  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  # Delete only if user hasn't updated their profile
  def handle_event("delete", %{"id" => id}, socket) do
    user_profile = Accounts.get_user_profile!(id)

    if is_nil(user_profile.last_seen_at) do
      {:ok, _} = Accounts.delete_user_profile(user_profile)
      {:noreply, stream_delete(socket, :user_profiles, user_profile)}
    else
      {:noreply, socket
       |> put_flash(:error, "Tidak boleh padam profil yang telah dikemaskini oleh pengguna")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>

      <main class="flex-1 p-6 transition-all duration-300">
        <div class="bg-gray-100 p-4 md:p-8 rounded-lg">
          <h1 class="text-xl font-bold mb-4">Senarai Pengguna</h1>

          <!-- Stats cards -->
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <div class="bg-white shadow rounded-lg p-4 text-center">
              <div class="text-2xl font-bold"><%= @stats.total_users %></div>
              <div class="text-gray-600">Jumlah Pengguna</div>
            </div>
            <div class="bg-white shadow rounded-lg p-4 text-center">
              <div class="text-2xl font-bold"><%= @stats.admins %></div>
              <div class="text-gray-600">Admin</div>
            </div>
            <div class="bg-white shadow rounded-lg p-4 text-center">
              <div class="text-2xl font-bold"><%= @stats.users %></div>
              <div class="text-gray-600">Staf</div>
            </div>
            <div class="bg-white shadow rounded-lg p-4 text-center">
              <div class="text-2xl font-bold"><%= @stats.active_users %></div>
              <div class="text-gray-600">Aktif 30 Hari</div>
            </div>
          </div>

          <!-- Table -->
          <.table
            id="user_profiles"
            rows={@streams.user_profiles}
            row_click={fn {_id, u} -> JS.patch(~p"/admin/user_profiles/#{u.id}?action=show") end}
          >
            <:col :let={{_id, u}} label="Nama Penuh">{u.full_name}</:col>
            <:col :let={{_id, u}} label="Emel">{u.user && u.user.email}</:col>
            <:col :let={{_id, u}} label="Jabatan">{u.department && u.department.name}</:col>
            <:col :let={{_id, u}} label="Jawatan">{u.position}</:col>
            <:col :let={{_id, u}} label="Status Pekerjaan">{UserProfile.human_employment_status(u.employment_status)}</:col>
            <:col :let={{_id, u}} label="Jantina">{UserProfile.human_gender(u.gender)}</:col>
            <:col :let={{_id, u}} label="No. Telefon">{u.phone_number}</:col>
            <:col :let={{_id, u}} label="Alamat">{u.address}</:col>

            <:action :let={{id, u}}>
              <.link phx-click={JS.push("delete", value: %{id: u.id}) |> hide("##{id}")} data-confirm="Anda yakin?">
                Delete
              </.link>
            </:action>
          </.table>

          <!-- Show Modal -->
          <.modal :if={@live_action == :show} id="user_profile-show-modal" show on_cancel={JS.patch(~p"/admin/user_profiles")}>
            <.live_component
              module={SpatoWeb.UserProfileLive.ShowComponent}
              id={@user_profile.id}
              title={@page_title}
              user_profile={@user_profile}
            />
          </.modal>
        </div>
      </main>
    </div>
    """
  end
end

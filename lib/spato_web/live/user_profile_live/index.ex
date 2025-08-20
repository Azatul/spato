defmodule SpatoWeb.UserProfileLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  alias Spato.Accounts
  alias Spato.Accounts.UserProfile
  alias Spato.Repo

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    stats = Accounts.user_stats()
    user_profiles = Accounts.list_user_profiles() |> Repo.preload([:user, :department])

    {:ok,
     socket
     |> assign(:page_title, "User Profiles")
     |> assign(:active_tab, "user_profiles")
     |> assign(:sidebar_open, true)
     |> assign(:total_users, stats.total_users)
     |> assign(:admin_users, stats.admins)
     |> assign(:staff_users, stats.users)
     |> assign(:active_users, stats.active_users)
     |> assign(:current_user, socket.assigns.current_user)
     |> stream(:user_profiles, user_profiles)}
  end

  @impl true
  def handle_params(params, _url, socket),
    do: {:noreply, apply_action(socket, socket.assigns.live_action, params)}

  defp apply_action(socket, :edit, %{"id" => id}) do
    user_profile = Accounts.get_user_profile!(id) |> Repo.preload([:user, :department])
    assign(socket, page_title: "Edit User Profile", user_profile: user_profile)
  end

  defp apply_action(socket, :new, _params),
    do: assign(socket, page_title: "New User Profile", user_profile: %UserProfile{})

  defp apply_action(socket, :index, _params),
    do: assign(socket, page_title: "Listing User Profiles", user_profile: nil)

  @impl true
  def handle_event("toggle_sidebar", _, socket),
    do: {:noreply, update(socket, :sidebar_open, &(!&1))}

  def handle_event("delete", %{"id" => id}, socket) do
    user_profile = Accounts.get_user_profile!(id)
    {:ok, _} = Accounts.delete_user_profile(user_profile)
    {:noreply, stream_delete(socket, :user_profiles, user_profile)}
  end

  @impl true
  def handle_info({SpatoWeb.UserProfileLive.FormComponent, {:saved, user_profile}}, socket),
    do: {:noreply, stream_insert(socket, :user_profiles, user_profile)}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>

      <main class="flex-1 p-6 transition-all duration-300">
        <div class="bg-gray-100 p-4 md:p-8 rounded-lg">
          <h1 class="text-xl font-bold mb-1">Senarai Pengguna</h1>
          <p class="text-md text-gray-500 mb-6">Urus dan semak semua Pengguna Sistem</p>

          <!-- Stats cards -->
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <.stat_card label="Jumlah Pengguna" value={@total_users} />
            <.stat_card label="Admin" value={@admin_users} />
            <.stat_card label="Staf Biasa" value={@staff_users} />
            <.stat_card label="Pengguna Aktif" value={@active_users} />
          </div>

          <.header>
            Senarai Profil Pengguna
            <:actions>
              <.link patch={~p"/admin/user_profiles/new"}><.button>Tambah Pengguna</.button></.link>
            </:actions>
          </.header>

          <.table
            id="user_profiles"
            rows={@streams.user_profiles}
            row_click={fn {_id, user_profile} -> JS.navigate(~p"/admin/user_profiles/#{user_profile}") end}
          >
            <:col :let={{_id, user_profile}} label="Nama Penuh">{user_profile.full_name}</:col>
            <:col :let={{_id, user_profile}} label="Emel">{user_profile.user && user_profile.user.email}</:col>
            <:col :let={{_id, user_profile}} label="Tarikh Lahir">{user_profile.dob}</:col>
            <:col :let={{_id, user_profile}} label="No. Kad Pengenalan">{user_profile.ic_number}</:col>
            <:col :let={{_id, user_profile}} label="Jantina">{user_profile.gender}</:col>
            <:col :let={{_id, user_profile}} label="No. Telefon">{user_profile.phone_number}</:col>
            <:col :let={{_id, user_profile}} label="Alamat">{user_profile.address}</:col>
            <:col :let={{_id, user_profile}} label="Jawatan">{user_profile.position}</:col>
            <:col :let={{_id, user_profile}} label="Status Pekerjaan">{user_profile.employment_status}</:col>
            <:col :let={{_id, user_profile}} label="Tarikh Lantikan">{user_profile.date_joined}</:col>
            <:col :let={{_id, user_profile}} label="Peranan">{user_profile.user && user_profile.user.role}</:col>
            <:col :let={{_id, user_profile}} label="Jabatan">{user_profile.department && user_profile.department.name}</:col>

            <:action :let={{_id, user_profile}}><.link patch={~p"/admin/user_profiles/#{user_profile}/edit"}>Edit</.link></:action>
            <:action :let={{id, user_profile}}>
              <.link phx-click={JS.push("delete", value: %{id: user_profile.id}) |> hide("##{id}")} data-confirm="Are you sure?">Delete</.link>
            </:action>
          </.table>

          <.modal :if={@live_action in [:new, :edit]} id="user_profile-modal" show on_cancel={JS.patch(~p"/admin/user_profiles")}>
            <.live_component
              module={SpatoWeb.UserProfileLive.FormComponent}
              id={@user_profile.id || :new}
              title={@page_title}
              action={@live_action}
              user_profile={@user_profile}
              current_user={@current_user}
              patch={~p"/admin/user_profiles"}
            />
          </.modal>
        </div>
      </main>
    </div>
    """
  end

  defp stat_card(assigns) do
    ~H"""
    <div class="bg-white p-6 rounded-lg shadow-md flex flex-col justify-between h-40">
      <div>
        <p class="text-sm text-gray-500"><%= @label %></p>
        <p class="text-5xl font-bold mt-1"><%= @value %></p>
      </div>
    </div>
    """
  end
end

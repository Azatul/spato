defmodule SpatoWeb.UserProfileLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar

  alias Spato.Accounts
  alias Spato.Accounts.UserProfile

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    total_users = Accounts.count_total_users()
    admin_users = Accounts.count_admins()
    staff_users = Accounts.count_staff()
    active_users = Accounts.count_active_users()

    {:ok,
     socket
     |> assign(:page_title, "User Profiles")
     |> assign(:active_tab, "user_profiles")
     |> assign(:sidebar_open, true)
     |> assign(:total_users, total_users)
     |> assign(:admin_users, admin_users)
     |> assign(:staff_users, staff_users)
     |> assign(:active_users, active_users)
     |> stream(:user_profiles, Accounts.list_user_profiles())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit User Profile")
    |> assign(:user_profile, Accounts.get_user_profile!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New User Profile")
    |> assign(:user_profile, %UserProfile{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing User Profiles")
    |> assign(:user_profile, nil)
  end

  @impl true
  def handle_event(event, params, socket) do
    case event do
      "toggle_sidebar" ->
        {:noreply, update(socket, :sidebar_open, &(!&1))}

      "delete" ->
        id = params["id"]
        user_profile = Accounts.get_user_profile!(id)
        {:ok, _} = Accounts.delete_user_profile(user_profile)
        {:noreply, stream_delete(socket, :user_profiles, user_profile)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({SpatoWeb.UserProfileLive.FormComponent, {:saved, user_profile}}, socket) do
    {:noreply, stream_insert(socket, :user_profiles, user_profile)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen">
      <.sidebar
        active_tab={@active_tab}
        current_user={@current_user}
        open={@sidebar_open}
        toggle_event="toggle_sidebar"
      />

      <main class="flex-1 p-6 transition-all duration-300">
        <div class="bg-gray-100 p-4 md:p-8 rounded-lg">
          <h1 class="text-xl font-bold mb-1">Senarai Pengguna</h1>
          <p class="text-md text-gray-500 mb-6">Urus dan semak semua Pengguna Sistem</p>

          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <div class="bg-white p-6 rounded-lg shadow-md flex flex-col justify-between h-40">
            <div>
              <p class="text-sm text-gray-500">Jumlah Pengguna</p>
              <p class="text-5xl font-bold mt-1"><%= @total_users %></p>
            </div>
          </div>
          <div class="bg-white p-6 rounded-lg shadow-md flex flex-col justify-between h-40">
            <div>
              <p class="text-sm text-gray-500">Admin</p>
              <p class="text-5xl font-bold mt-1"><%= @admin_users %></p>
            </div>
          </div>
          <div class="bg-white p-6 rounded-lg shadow-md flex flex-col justify-between h-40">
            <div>
              <p class="text-sm text-gray-500">Staf Biasa</p>
              <p class="text-5xl font-bold mt-1"><%= @staff_users %></p>
            </div>
          </div>
          <div class="bg-white p-6 rounded-lg shadow-md flex flex-col justify-between h-40">
            <div>
              <p class="text-sm text-gray-500">Pengguna Aktif</p>
              <p class="text-5xl font-bold mt-1"><%= @active_users %></p>
            </div>
          </div>
        </div>

          <.header>
            Senarai Profil Pengguna
            <:actions>
              <.link patch={~p"/user_profiles/new"}>
                <.button>Tambah Pengguna</.button>
              </.link>
            </:actions>
          </.header>

          <.table
            id="user_profiles"
            rows={@streams.user_profiles}
            row_click={fn {_id, user_profile} -> JS.navigate(~p"/user_profiles/#{user_profile}") end}
          >
            <:col :let={{_id, user_profile}} label="Nama Penuh">{user_profile.full_name}</:col>
            <:col :let={{_id, user_profile}} label="Tarikh Lahir">{user_profile.dob}</:col>
            <:col :let={{_id, user_profile}} label="No. IC">{user_profile.ic_number}</:col>
            <:col :let={{_id, user_profile}} label="Jantina">{user_profile.gender}</:col>
            <:col :let={{_id, user_profile}} label="No. Telefon">{user_profile.phone_number}</:col>
            <:col :let={{_id, user_profile}} label="Alamat">{user_profile.address}</:col>
            <:col :let={{_id, user_profile}} label="Jawatan">{user_profile.position}</:col>
            <:col :let={{_id, user_profile}} label="Status Pekerjaan">{user_profile.employment_status}</:col>
            <:col :let={{_id, user_profile}} label="Tarikh Lantikan">{user_profile.date_joined}</:col>
            <:action :let={{_id, user_profile}}>
              <div class="sr-only">
                <.link navigate={~p"/user_profiles/#{user_profile}"}>Show</.link>
              </div>
              <.link patch={~p"/user_profiles/#{user_profile}/edit"}>Edit</.link>
            </:action>
            <:action :let={{id, user_profile}}>
              <.link
                phx-click={JS.push("delete", value: %{id: user_profile.id}) |> hide("##{id}")}
                data-confirm="Are you sure?"
              >
                Delete
              </.link>
            </:action>
          </.table>

          <.modal :if={@live_action in [:new, :edit]} id="user_profile-modal" show on_cancel={JS.patch(~p"/user_profiles")}>
            <.live_component
              module={SpatoWeb.UserProfileLive.FormComponent}
              id={@user_profile.id || :new}
              title={@page_title}
              action={@live_action}
              user_profile={@user_profile}
              patch={~p"/user_profiles"}
            />
          </.modal>
        </div>
      </main>
    </div>
    """
  end
end

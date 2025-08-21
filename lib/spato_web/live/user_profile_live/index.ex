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

  # Sidebar toggle
  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user_with_profile!(id)

    case Accounts.delete_user(user) do
      {:ok, _} ->
        # if the user has a profile, remove that from stream
        if user.user_profile do
          {:noreply, stream_delete(socket, :user_profiles, user.user_profile)}
        else
          # if no profile, just remove the user by id
          {:noreply, stream_delete(socket, :user_profiles, %{id: user.id})}
        end

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Tidak boleh padam pengguna")}
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
            <:col :let={{_id, u}} label="Nama Penuh">
            <%= if u.user_profile && u.user_profile.full_name do %>
              <%= u.user_profile.full_name %>
            <% else %>
              Belum diisi
            <% end %>
          </:col>

          <:col :let={{_id, u}} label="Emel">
            <%= u.email %>
          </:col>

          <:col :let={{_id, u}} label="Jabatan">
            <%= if u.user_profile && u.user_profile.department do %>
              <%= u.user_profile.department.name %>
            <% else %>
              Belum diisi
            <% end %>
          </:col>

          <:col :let={{_id, u}} label="Jawatan">
            <%= u.user_profile && u.user_profile.position || "Belum diisi" %>
          </:col>

          <:col :let={{_id, u}} label="Status Pekerjaan">
            <%= if u.user_profile && u.user_profile.employment_status do %>
              <%= UserProfile.human_employment_status(u.user_profile.employment_status) %>
            <% else %>
              Belum diisi
            <% end %>
          </:col>

          <:col :let={{_id, u}} label="Jantina">
            <%= if u.user_profile && u.user_profile.gender do %>
              <%= UserProfile.human_gender(u.user_profile.gender) %>
            <% else %>
              Belum diisi
            <% end %>
          </:col>

          <:col :let={{_id, u}} label="No. Telefon">
            <%= u.user_profile && u.user_profile.phone_number || "Belum diisi" %>
          </:col>

          <:col :let={{_id, u}} label="Alamat">
            <%= u.user_profile && u.user_profile.address || "Belum diisi" %>
          </:col>


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
              id={@user.id}
              title={@page_title}
              user={@user}
              user_profile={@user_profile} />
          </.modal>

        </div>
      </main>
    </div>
    """
  end
end

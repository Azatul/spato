defmodule SpatoWeb.UserProfileLive.Show do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar

  alias Spato.Accounts

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, "user_profiles")
     |> assign(:sidebar_open, true)}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:user_profile, Accounts.get_user_profile!(id))}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  defp page_title(:show), do: "Show User Profile"
  defp page_title(:edit), do: "Edit User Profile"

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
          <h1 class="text-xl md:text-2xl font-bold mb-6">Maklumat Pengguna</h1>

          <div class="flex flex-col items-center mb-6">
            <img src="/images/user_icon.png" alt="User Profile" class="h-24 w-24 rounded-full border-2 border-gray-300 mb-4" />
            </div>

          <div class="space-y-4">
            <div>
              <p class="text-sm text-gray-600 mb-1">Nama Penuh</p>
              <div class="bg-white p-3 rounded-lg border border-gray-300">
                <%= @user_profile.full_name %>
              </div>
            </div>

            <div>
              <p class="text-sm text-gray-600 mb-1">Nombor Kad Pengenalan</p>
              <div class="bg-white p-3 rounded-lg border border-gray-300">
                <%= @user_profile.ic_number %>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p class="text-sm text-gray-600 mb-1">Tarikh Lahir</p>
                <div class="bg-white p-3 rounded-lg border border-gray-300 flex items-center justify-between">
                  <%= @user_profile.dob %>
                  <i class="fa-solid fa-calendar"></i>
                </div>
              </div>
              <div>
                <p class="text-sm text-gray-600 mb-1">Jantina</p>
                <div class="bg-white p-3 rounded-lg border border-gray-300">
                  <%= @user_profile.gender %>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p class="text-sm text-gray-600 mb-1">No. Telefon</p>
                <div class="bg-white p-3 rounded-lg border border-gray-300">
                  <%= @user_profile.phone_number %>
                </div>
              </div>
              <div>
                <p class="text-sm text-gray-600 mb-1">Status Pekerjaan</p>
                <div class="bg-white p-3 rounded-lg border border-gray-300">
                  <%= @user_profile.employment_status %>
                </div>
              </div>
            </div>

            <div>
              <p class="text-sm text-gray-600 mb-1">Alamat</p>
              <div class="bg-white p-3 rounded-lg border border-gray-300">
                <%= @user_profile.address %>
              </div>
            </div>

            <div class="border-t border-gray-200 my-6"></div>

            <div>
              <p class="text-sm text-gray-600 mb-1">Nama Jabatan</p>
              <div class="bg-white p-3 rounded-lg border border-gray-300">
                </div>
            </div>

            <div>
              <p class="text-sm text-gray-600 mb-1">Jawatan</p>
              <div class="bg-white p-3 rounded-lg border border-gray-300">
                <%= @user_profile.position %>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <p class="text-sm text-gray-600 mb-1">Tarikh Lantikan</p>
                <div class="bg-white p-3 rounded-lg border border-gray-300 flex items-center justify-between">
                  <%= @user_profile.date_joined %>
                  <i class="fa-solid fa-calendar"></i>
                </div>
              </div>
              <div>
                <p class="text-sm text-gray-600 mb-1">Status Pekerjaan</p>
                <div class="bg-white p-3 rounded-lg border border-gray-300">
                  <%= @user_profile.employment_status %>
                </div>
              </div>
            </div>
          </div>

          <div class="flex justify-end mt-6">
            <.link patch={~p"/admin/user_profiles/#{@user_profile}/show/edit"}>
              <.button>Kemaskini Profil</.button>
            </.link>
          </div>
        </div>
      </main>
    </div>

    <.modal :if={@live_action == :edit} id="user_profile-modal" show on_cancel={JS.patch(~p"/admin/user_profiles/#{@user_profile}")}>
      <.live_component
        module={SpatoWeb.UserProfileLive.FormComponent}
        id={@user_profile.id}
        title={@page_title}
        action={@live_action}
        user_profile={@user_profile}
        patch={~p"/admin/user_profiles/#{@user_profile}"}
      />
    </.modal>
    """
  end
end

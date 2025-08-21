defmodule SpatoWeb.UserProfileLive.ShowComponent do
  use SpatoWeb, :live_component

  alias Spato.Accounts.UserProfile

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow p-6 w-full max-w-2xl mx-auto">
      <h2 class="text-xl font-bold mb-4"><%= @title %></h2>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <p class="text-sm text-gray-500">Nama Penuh</p>
          <p class="font-medium"><%= @user_profile.full_name %></p>
        </div>

        <div>
          <p class="text-sm text-gray-500">Emel</p>
          <p class="font-medium"><%= @user_profile.user && @user_profile.user.email %></p>
        </div>

        <div>
          <p class="text-sm text-gray-500">Jabatan</p>
          <p class="font-medium"><%= @user_profile.department && @user_profile.department.name %></p>
        </div>

        <div>
          <p class="text-sm text-gray-500">Jawatan</p>
          <p class="font-medium"><%= @user_profile.position %></p>
        </div>

        <div>
          <p class="text-sm text-gray-500">Status Pekerjaan</p>
          <p class="font-medium"><%= UserProfile.human_employment_status(@user_profile.employment_status) %></p>
        </div>

        <div>
          <p class="text-sm text-gray-500">Jantina</p>
          <p class="font-medium"><%= UserProfile.human_gender(@user_profile.gender) %></p>
        </div>

        <div>
          <p class="text-sm text-gray-500">No. Telefon</p>
          <p class="font-medium"><%= @user_profile.phone_number %></p>
        </div>

        <div>
          <p class="text-sm text-gray-500">Alamat</p>
          <p class="font-medium"><%= @user_profile.address %></p>
        </div>
      </div>

      <div class="mt-6 flex justify-end">
        <.button phx-click={JS.patch(~p"/admin/user_profiles")}>
          Tutup
        </.button>
      </div>
    </div>
    """
  end
end

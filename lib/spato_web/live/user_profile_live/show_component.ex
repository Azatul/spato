defmodule SpatoWeb.UserProfileLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-xl md:text-2xl font-bold mb-6">Maklumat Pengguna</h2>

      <div class="flex flex-col items-center mb-6">
        <img src="/images/giraffe.jpg" alt="User Profile" class="h-24 w-24 rounded-full border-2 border-gray-300 mb-4" />
      </div>

      <div class="space-y-4">
        <!-- Basic Info -->
        <.info label="Nama Penuh"><%= @user_profile.full_name %></.info>
        <.info label="Emel"><%= @user_profile.user && @user_profile.user.email %></.info>
        <.info label="Nombor Kad Pengenalan"><%= @user_profile.ic_number %></.info>

        <!-- Birth & Gender -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.info label="Tarikh Lahir"><%= @user_profile.dob %></.info>
          <.info label="Jantina"><%= @user_profile.gender %></.info>
        </div>

        <!-- Phone & Employment Status -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.info label="No. Telefon"><%= @user_profile.phone_number %></.info>
          <.info label="Status Pekerjaan"><%= @user_profile.employment_status %></.info>
        </div>

        <!-- Address -->
        <.info label="Alamat"><%= @user_profile.address %></.info>

        <!-- Department & Position -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.info label="Jabatan"><%= @user_profile.department && @user_profile.department.name %></.info>
          <.info label="Jawatan"><%= @user_profile.position %></.info>
        </div>

        <!-- Date Joined & Role -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.info label="Tarikh Lantikan"><%= @user_profile.date_joined %></.info>
          <.info label="Peranan"><%= @user_profile.user && @user_profile.user.role %></.info>
        </div>
      </div>
    </div>
    """
  end

  defp info(assigns) do
    ~H"""
    <div>
      <p class="text-sm text-gray-600 mb-1"><%= @label %></p>
      <div class="bg-white p-3 rounded-lg border border-gray-300">
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end
end

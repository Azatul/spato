defmodule SpatoWeb.UserProfileLive.ShowComponent do
  use SpatoWeb, :live_component
  alias Spato.Accounts.UserProfile

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <h2 class="text-lg font-bold mb-4"><%= @user_profile.full_name || "Belum diisi" %></h2>
      <h2 class="text-lg font-bold mb-4"><%= @user.role %></h2>

      <div class="mb-4">
        <%= if @user_profile.profile_picture_url do %>
          <img src={@user_profile.profile_picture_url} alt="Profile picture" class="w-full max-w-sm rounded-md shadow" />
        <% end %>
      </div>

      <%= if @user_profile do %>
        <p><b>Nama:</b> <%= @user_profile.full_name || "Belum diisi" %></p>
        <p><b>Jabatan:</b> <%= @user_profile.department && @user_profile.department.name || "Belum diisi" %></p>
        <p><b>Jawatan:</b> <%= @user_profile.position || "Belum diisi" %></p>
        <p><b>Status Pekerjaan:</b>
          <%= if @user_profile.employment_status do %>
            <%= UserProfile.human_employment_status(@user_profile.employment_status) %>
          <% else %>
            Belum diisi
          <% end %>
        </p>
        <p><b>Jantina:</b>
          <%= if @user_profile.gender do %>
            <%= UserProfile.human_gender(@user_profile.gender) %>
          <% else %>
            Belum diisi
          <% end %>
        </p>
        <p><b>No. Telefon:</b> <%= @user_profile.phone_number || "Belum diisi" %></p>
        <p><b>Alamat:</b> <%= @user_profile.address || "Belum diisi" %></p>
        <p><b>Peranan:</b> <%= @user.role %></p>
        <p><b>Emel:</b> <%= @user.email %></p>
      <% else %>
        <p class="text-gray-600 italic">Profil pengguna ini belum diwujudkan.</p>
      <% end %>
    </div>
    """
  end
end

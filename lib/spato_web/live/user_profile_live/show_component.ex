defmodule SpatoWeb.UserProfileLive.ShowComponent do
  use SpatoWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4">
      <h2 class="text-lg font-bold mb-4"><%= @user.email %></h2>

      <%= if @user_profile do %>
        <p><b>Nama:</b> <%= @user_profile.full_name %></p>
        <p><b>Jabatan:</b> <%= @user_profile.department && @user_profile.department.name %></p>
        <p><b>Jawatan:</b> <%= @user_profile.position %></p>
        <!-- etc -->
      <% else %>
        <p class="text-gray-600 italic">Profil pengguna ini belum diwujudkan.</p>
      <% end %>
    </div>
    """
  end
end

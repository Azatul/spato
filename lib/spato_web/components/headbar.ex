defmodule SpatoWeb.Components.Headbar do
  use Phoenix.Component
  import SpatoWeb.CoreComponents, only: [icon: 1]

  @moduledoc """
  A top navigation bar that stays aligned with the sidebar.

  - Accepts the same `open` flag and `toggle_event` used by the sidebar, so the
    headbar shifts its left offset to match `w-64` (open) or `w-20` (collapsed).
  - Shows a left toggle button, optional title/actions, and a user menu with
    Settings and Log Out options.
  """

  attr :current_user, :map, required: true
  attr :open, :boolean, default: true
  attr :toggle_event, :string, default: nil
  attr :toggle_image_src, :string, default: nil
  attr :toggle_image_alt, :string, default: "Toggle sidebar"
  attr :class, :string, default: nil
  attr :title, :string, default: nil
  attr :full_width, :boolean, default: false
  attr :notifications, :list, default: []
  attr :unread_count, :integer, default: 0
  attr :show_notifications, :boolean, default: false

  slot :actions

  def headbar(assigns) do
    ~H"""
    <header
      class={[
        "fixed top-0 right-0 z-40 bg-white border-b border-gray-200 h-16 flex items-center justify-between px-4 sm:px-6 lg:px-8 transition-all duration-300",
        @full_width && "left-0",
        !@full_width && @open && "left-64",
        !@full_width && !@open && "left-20",
        @class
      ]}
    >
      <div class="flex items-center gap-3">
        <button
          :if={@toggle_event}
          phx-click={@toggle_event}
          type="button"
          title="Toggle sidebar"
          class="p-2 rounded-md hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-gray-300"
        >
          <img
            :if={@toggle_image_src}
            src={@toggle_image_src}
            alt={@toggle_image_alt}
            class="w-6 h-6 object-contain"
          />
          <.icon :if={is_nil(@toggle_image_src)} name="hero-bars-3" class="w-6 h-6" />
        </button>

        <h1 :if={@title} class="text-base font-semibold text-gray-900">
          {@title}
        </h1>

        <div :if={@actions != []} class="ml-2 flex items-center gap-2">
          {render_slot(@actions)}
        </div>
      </div>

      <div class="flex items-center gap-4">
        <!-- Notification Bell -->
        <div class="relative">
          <button
            phx-click="toggle_notifications"
            class="relative p-2 text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-full"
            title="Notifikasi"
          >
            <.icon name="hero-bell" class="w-6 h-6" />
            <%= if @unread_count > 0 do %>
              <span class="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center">
                <%= @unread_count %>
              </span>
            <% end %>
          </button>

          <%= if @show_notifications do %>
            <div class="absolute right-0 mt-2 w-80 bg-white shadow-lg rounded-lg border border-gray-200 z-50 max-h-96 overflow-y-auto">
              <div class="p-3 border-b border-gray-200">
                <h3 class="text-sm font-semibold text-gray-900">Notifikasi</h3>
              </div>

              <%= if @notifications == [] do %>
                <div class="p-4 text-center text-gray-500 text-sm">
                  Tiada notifikasi
                </div>
              <% else %>
                <%= for notif <- @notifications do %>
                  <div class={[
                    "p-3 border-b border-gray-100 hover:bg-gray-50 cursor-pointer transition-colors",
                    notif.status == "unread" && "bg-blue-50"
                  ]}
                      phx-click="read_notification"
                      phx-value-id={notif.id}>
                    <div class="flex items-start gap-2">
                      <div class="flex-1">
                        <p class={[
                          "font-medium text-sm",
                          notif.status == "unread" && "text-gray-900",
                          notif.status == "read" && "text-gray-700"
                        ]}>
                          <%= notif.title %>
                        </p>
                        <p class="text-xs text-gray-600 mt-1"><%= notif.message %></p>
                        <p class="text-xs text-gray-400 mt-1">
                          <%= Calendar.strftime(notif.inserted_at, "%d/%m/%Y %H:%M") %>
                        </p>
                      </div>
                      <%= if notif.status == "unread" do %>
                        <div class="w-2 h-2 bg-blue-500 rounded-full mt-1"></div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>
          <% end %>
        </div>

        <span :if={@current_user.role} class="hidden sm:inline text-sm text-gray-600">
          {Spato.Accounts.User.display_role(@current_user)}
        </span>

        <details class="relative group">
          <summary class="list-none cursor-pointer flex items-center gap-2 select-none">
            <span class="hidden sm:inline text-sm font-medium text-gray-900">
              {Spato.Accounts.User.display_name(@current_user)}
            </span>

            <img
              src={
                case Map.get(@current_user, :user_profile) do
                  %{profile_picture_url: url} when is_binary(url) and byte_size(url) > 0 -> url
                  _ -> Map.get(@current_user, :avatar_url) || "/images/default-image.jpg"
                end
              }
              alt="Avatar"
              class="w-9 h-9 rounded-full object-cover border border-gray-300"
            />
          </summary>
          <ul class="absolute right-0 mt-2 w-40 bg-white border border-gray-200 rounded-lg shadow-lg p-2">
            <!-- Avatar section -->
            <div class="flex justify-center mb-2">
              <img
                :if={Map.get(@current_user, :user_profile)}
                src={
                  case Map.get(@current_user, :user_profile) do
                    %{profile_picture_url: url} when is_binary(url) and byte_size(url) > 0 -> url
                    _ -> Map.get(@current_user, :avatar_url) || "/images/default-image.jpg"
                  end
                }
                alt="Avatar"
                class="w-12 h-12 rounded-full object-cover border border-gray-300"
              />
            </div>

            <!-- Menu items -->
            <li>
              <.link
                patch="/users/settings"
                class="flex items-center gap-2 px-3 py-2 rounded-md hover:bg-gray-100"
              >
                <.icon name="hero-cog-6-tooth" class="w-4 h-4" /> Tetapan
              </.link>
            </li>
            <li>
              <.link
                href="/users/log_out"
                method="delete"
                class="flex items-center gap-2 px-3 py-2 rounded-md hover:bg-gray-100 text-red-600"
              >
                <.icon name="hero-arrow-right-on-rectangle-solid" class="w-4 h-4" /> Log Keluar
              </.link>
            </li>
          </ul>
        </details>
      </div>
    </header>
    """
  end
end

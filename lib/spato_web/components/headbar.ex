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
                  _ -> Map.get(@current_user, :avatar_url) || "/images/avatar-placeholder.png"
                end
              }
              alt="Avatar"
              class="w-9 h-9 rounded-full object-cover border border-gray-200"
            />
          </summary>

          <ul class="absolute right-0 mt-2 w-52 bg-white border border-gray-200 rounded-lg shadow-lg p-2">
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
                <.icon name="hero-arrow-left-on-rectangle-solid" class="w-4 h-4" /> Log Keluar
              </.link>
            </li>
          </ul>
        </details>
      </div>
    </header>
    """
  end
end

defmodule SpatoWeb.UserProfileLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Accounts
  alias Spato.Accounts.UserProfile
  alias SpatoWeb.UserRegistrationLive.FormComponent

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    registration_changeset = Accounts.change_user_registration(%Accounts.User{})

    {:ok,
     socket
     |> assign(:page_title, "Senarai Pengguna")
     |> assign(:active_tab, "user_profiles")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:stats, Accounts.user_stats())
     |> assign(:show_registration_modal, false)
     |> assign(:form, to_form(registration_changeset, as: "user"))
     |> assign(:roles, [{"Admin", "admin"}, {"User", "user"}])
     |> assign(:check_errors, false)
     |> assign(:user, nil)
     |> assign(:user_profile, nil)
     |> assign(:page, 1)
     |> assign(:total_pages, 1)
     |> assign(:filtered_count, 0)
     |> assign(:search_query, "")
     |> assign(:filter_role, "all")
     |> assign(:filter_department, "all")
     |> assign(:departments, Accounts.list_departments())
     |> stream(:user_profiles, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    %{users_page: users, total: total, total_pages: total_pages, page: page} =
      Accounts.list_users_paginated(%{
        "page" => Map.get(params, "page", "1"),
        "search" => Map.get(params, "q", ""),
        "role" => Map.get(params, "role", "all"),
        "department" => Map.get(params, "department", "all")
      })

    socket =
      socket
      |> assign(:page, page)
      |> assign(:total_pages, total_pages)
      |> assign(:filtered_count, total)
      |> assign(:search_query, Map.get(params, "q", ""))
      |> assign(:filter_role, Map.get(params, "role", "all"))
      |> assign(:filter_department, Map.get(params, "department", "all"))
      |> stream(:user_profiles, users, reset: true)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # Show modal
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

  @impl true
  def handle_info({FormComponent, {:saved, user}}, socket) do
    user_with_profile = Accounts.get_user_with_profile!(user.id)

    {:noreply,
     socket
     |> stream_insert(:user_profiles, user_with_profile)
     |> assign(:stats, Accounts.user_stats())
     |> put_flash(:info, "Pengguna berjaya didaftarkan!")
     |> assign(show_registration_modal: false, check_errors: false)}
  end

  # Sidebar toggle
  @impl true
  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  # Modal toggle
  def handle_event("show_registration_modal", _, socket) do
    {:noreply, assign(socket, show_registration_modal: true)}
  end

  def handle_event("hide_registration_modal", _, socket) do
    {:noreply, assign(socket, show_registration_modal: false, check_errors: false)}
  end

  # Delete user
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user_with_profile!(id)
    new_total = socket.assigns.filtered_count - 1
    case Accounts.delete_user(user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> stream_delete(:user_profiles, user)
         |> assign(:stats, Accounts.user_stats())
         |> put_flash(:info, "Pengguna berjaya dipadam")
         |> assign(:filtered_count, new_total)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Tidak boleh padam pengguna")}
    end
  end

  # Search (patch URL with query)
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply,
     push_patch(socket,
       to: ~p"/admin/user_profiles?page=1&q=#{q}&role=#{socket.assigns.filter_role}"
     )}
  end

  def handle_event("filter_users", %{"department" => department, "role" => role}, socket) do
    {:noreply,
     push_patch(socket,
       to:
         ~p"/admin/user_profiles?page=1&q=#{socket.assigns.search_query}&role=#{role}&department=#{department}"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="flex h-screen overflow-hidden">
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>
      <div class="flex flex-col flex-1">
      <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

      <main class="flex-1 overflow-y-auto pt-20 p-6 transition-all duration-300 bg-gray-100">
      <section class="mb-4">
        <h1 class="text-xl font-bold mb-1">Urus Pengguna</h1>
        <p class="text-md text-gray-500 mb-4">Semak dan urus semua pengguna dalam sistem</p>
      </section>

        <!-- Top Section: Stats Cards -->
        <section class="mb-4">
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <%= for {label, value} <- [{"Jumlah Pengguna Berdaftar", @stats.total_users},
                                      {"Admin", @stats.admins},
                                      {"Staf Biasa", @stats.users},
                                      {"Pengguna Aktif", @stats.active_users}] do %>
              <% number_color =
                case label do
                  "Jumlah Pengguna Berdaftar" -> "text-gray-700"
                  "Admin" -> "text-green-500"
                  "Staf Biasa" -> "text-purple-500"
                  "Pengguna Aktif" -> "text-blue-500"
                end %>
              <div class="bg-white p-4 rounded-xl shadow-md flex flex-col justify-between h-30 transition-transform hover:scale-105">
                <div>
                  <p class="text-sm text-gray-500"><%= label %></p>
                  <p class={"text-3xl font-bold mt-1 #{number_color}"}><%= value %></p>
                </div>
              </div>
            <% end %>
          </div>
        </section>

        <!-- Middle Section: Add User Button -->
        <section class="mb-4 flex justify-end">
          <.button
            phx-click="show_registration_modal"
            class="inline-flex items-center justify-center rounded-md border border-transparent bg-gray-900 px-4 py-2 text-sm font-semibold text-white hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-800 focus:ring-offset-2"
          >
            Tambah Pengguna
          </.button>
        </section>


        <!-- Bottom Section: User Table -->
        <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">

        <!-- Header: Add + Search + Filter -->
          <div class="flex flex-col mb-4 gap-2">
              <div class="flex items-center justify-between">
                <h2 class="text-lg font-semibold text-gray-900">Senarai Pengguna</h2>
              </div>

            <div class="flex flex-wrap gap-2 mt-2">
              <form phx-change="search" class="flex-1 min-w-[200px]">
                <input type="text" name="q" value={@search_query} placeholder="Cari nama, jawatan atau jabatan..." class="w-full border rounded-md px-2 py-1 text-sm"/>
              </form>

              <!-- Filter by user profile -->
              <form phx-change="filter_users" class="flex gap-2">
                <select name="department" class="border rounded-md px-2 pr-8 py-1 text-sm">
                  <option value="all" selected={@filter_department in [nil, "all"]}>Semua Jabatan</option>
                  <option value="belum_diisi" selected={@filter_department == "belum_diisi"}>Belum Diisi</option>
                  <%= for dept <- @departments do %>
                    <option value={dept.id} selected={@filter_department == to_string(dept.id)}><%= dept.name %></option>
                  <% end %>
                </select>

                <select name="role" class="border rounded-md px-2 pr-8 py-1 text-sm">
                  <option value="all" selected={@filter_role in [nil, "all"]}>Semua Status</option>
                  <option value="admin" selected={@filter_role == "admin"}>Admin</option>
                  <option value="user" selected={@filter_role == "user"}>Staf Biasa</option>
                </select>
              </form>
            </div>
          </div>

        <!-- Users count message -->
          <div class="mb-2 text-sm text-gray-600">
            <%= if @filtered_count == 0 do %>
              Tiada pengguna ditemui
            <% else %>
              <%= @filtered_count %> pengguna ditemui
            <% end %>
          </div>

          <.table
            id="user_profiles"
            rows={@streams.user_profiles}
            row_click={fn {_id, u} -> JS.patch(~p"/admin/user_profiles/#{u.id}?action=show") end}
          >
            <:col :let={{_id, u}} label="ID"><%= u.id %></:col>
            <:col :let={{_id, u}} label="Nama Penuh"><%= if u.user_profile && Map.has_key?(u.user_profile, :full_name), do: u.user_profile.full_name, else: "Belum diisi" %></:col>
            <:col :let={{_id, u}} label="Jawatan"><%= if u.user_profile && Map.has_key?(u.user_profile, :position), do: u.user_profile.position, else: "Belum diisi" %></:col>
            <:col :let={{_id, u}} label="Jabatan"><%= if u.user_profile && u.user_profile.department && Map.has_key?(u.user_profile.department, :name), do: u.user_profile.department.name, else: "Belum diisi" %></:col>
            <:col :let={{_id, u}} label="Jantina"><%= if u.user_profile && u.user_profile.gender, do: UserProfile.human_gender(u.user_profile.gender), else: "Belum diisi" %></:col>
            <:col :let={{_id, u}} label="Emel & No. Telefon">
              <div class="flex flex-col">
                <!-- Emel -->
                <div class="text-sm font-medium text-gray-900">
                  <%= u.email %>
                </div>

                <!-- No. Telefon (slightly lighter color) -->
                <div class="text-xs text-gray-500">
                  <%= if u.user_profile && u.user_profile.phone_number do %>
                    <%= u.user_profile.phone_number %>
                  <% else %>
                    Belum diisi
                  <% end %>
                </div>
              </div>
            </:col>
            <:col :let={{_id, u}} label="Alamat"><%= if u.user_profile && Map.has_key?(u.user_profile, :address), do: u.user_profile.address, else: "Belum diisi" %></:col>
            <:col :let={{_id, u}} label="Status Pekerjaan">
              <%= if u.user_profile && u.user_profile.employment_status do %>
                <span class={"px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
                  case u.user_profile.employment_status do
                    :full_time -> "bg-green-500"
                    :part_time -> "bg-blue-500"
                    :contract -> "bg-yellow-500 text-black"
                    :intern -> "bg-gray-500"
                    _ -> "bg-gray-400"
                  end
                }>
                  <%= UserProfile.human_employment_status(u.user_profile.employment_status) %>
                </span>
              <% else %>
                <span class="px-1.5 py-0.5 rounded-full text-xs font-semibold bg-gray-300 text-gray-700">
                  Belum diisi
                </span>
              <% end %>
            </:col>

            <:col :let={{_id, u}} label="Peranan">
              <span class={"px-1.5 py-0.5 rounded-full text-white text-xs font-semibold " <>
                case u.role do
                  "admin" -> "bg-green-500"
                  "user" -> "bg-purple-500"
                  _ -> "bg-gray-400"
                end
              }>
                <%= if u.role, do: UserProfile.human_role(u.role), else: "Belum diisi" %>
              </span>
            </:col>
            <:col :let={{_id, u}} label="Tarikh Lantikan"><%= if u.user_profile && Map.has_key?(u.user_profile, :date_joined), do: u.user_profile.date_joined, else: "Belum diisi" %></:col>

            <:action :let={{id, u}}>
              <%= if u.id != @current_user.id and u.role != "admin" do %>
                <.link phx-click={JS.push("delete", value: %{id: u.id}) |> hide("##{id}")} data-confirm="Anda yakin?">
                  Padam
                </.link>
              <% else %>
                <!-- No delete option for self or admins -->
              <% end %>
            </:action>

          </.table>
        </section>

         <!-- Pagination -->
          <%= if @filtered_count > 0 do %>
          <div class="relative flex items-center mt-4">
            <!-- Previous button -->
            <div class="flex-1">
              <.link
                patch={~p"/admin/user_profiles?page=#{max(@page - 1, 1)}&q=#{@search_query}&role=#{@filter_role}"}
                class={"px-3 py-1 border rounded #{if @page == 1, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
              >
                Sebelumnya
              </.link>
            </div>

            <!-- Page numbers (centered) -->
            <div class="absolute left-1/2 transform -translate-x-1/2 flex space-x-1">
              <%= for p <- 1..@total_pages do %>
                <.link
                  patch={~p"/admin/user_profiles?page=#{p}&q=#{@search_query}&role=#{@filter_role}"}
                  class={"px-3 py-1 border rounded #{if p == @page, do: "bg-gray-700 text-white", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
                >
                  <%= p %>
                </.link>
              <% end %>
            </div>

            <!-- Next button -->
            <div class="flex-1 text-right">
              <.link
                patch={~p"/admin/user_profiles?page=#{min(@page + 1, @total_pages)}&q=#{@search_query}&role=#{@filter_role}"}
                class={"px-3 py-1 border rounded #{if @page == @total_pages, do: "bg-gray-200 text-gray-500 cursor-not-allowed", else: "bg-white text-gray-700 hover:bg-gray-100"}"}
              >
                Seterusnya
              </.link>
            </div>
          </div>
          <% end %>

        <!-- Modals (Show & Registration) -->
        <.modal :if={@live_action == :show} id="user-profile-show-modal" show on_cancel={JS.patch(~p"/admin/user_profiles")}>
          <.live_component
            module={SpatoWeb.UserProfileLive.ShowComponent}
            id={@user.id}
            title={@page_title}
            user={@user}
            user_profile={@user_profile}
          />
        </.modal>

        <.modal :if={@show_registration_modal} id="new-user-modal" show on_cancel={JS.push("hide_registration_modal")}>
        <.live_component
          module={FormComponent}
          id="new-user"
          title="Daftar Pengguna Baru"
          action={:new}
          user={%Accounts.User{}}
          patch={~p"/admin/user_profiles"}
          form={@form}
          roles={@roles}
          check_errors={@check_errors}
        />
        </.modal>
      </main>
    </div>
    </div>
    """
  end
end

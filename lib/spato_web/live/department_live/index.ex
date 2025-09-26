defmodule SpatoWeb.DepartmentLive.Index do
  use SpatoWeb, :live_view
  import SpatoWeb.Components.Sidebar
  import SpatoWeb.Components.Headbar

  alias Spato.Accounts
  alias Spato.Accounts.Department
  alias SpatoWeb.DepartmentLive.{FormComponent, ShowComponent}

  on_mount {SpatoWeb.UserAuth, :ensure_authenticated}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Senarai Jabatan")
     |> assign(:active_tab, "departments")
     |> assign(:sidebar_open, true)
     |> assign(:current_user, socket.assigns.current_user)
     |> assign(:dept_counts, Accounts.department_staff_counts())
     |> assign(:stats, Accounts.department_stats())
     |> assign(:page, 1)
     |> assign(:total_pages, 1)
     |> assign(:filtered_count, 0)
     |> assign(:search_query, "")
     |> stream(:departments, Accounts.list_departments())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(assign(socket, :live_action, socket.assigns.live_action), socket.assigns.live_action, params)}
  end

  # Modal actions
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Jabatan Baru")
    |> assign(:department, %Department{})
    |> assign(:stats, Accounts.department_stats())
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Kemaskini Jabatan")
    |> assign(:department, Accounts.get_department!(id))
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Lihat Jabatan")
    |> assign(:department, Accounts.get_department!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Senarai Jabatan")
    |> assign(:department, nil)
  end

  # Handle saves from FormComponent
  @impl true
  def handle_info({FormComponent, {:saved, department}}, socket) do
    {:noreply, stream_insert(socket, :departments, department)}
  end

  # Delete department
  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    department = Accounts.get_department!(id)
    {:ok, _} = Accounts.delete_department(department)
    {:noreply,
     stream_delete(socket, :departments, department)
     |> assign(:stats, Accounts.department_stats())}
  end

  # Toggle sidebar
  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  def handle_event("search", %{"q" => q}, socket) do
    page_data = Spato.Accounts.list_departments_paginated(%{"search" => q})
    {:noreply,
     assign(socket,
       departments_page: page_data[:departments_page],
       total_pages: page_data[:total_pages],
       page: page_data[:page],
       search_query: q
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden">
      <!-- Sidebar -->
      <.sidebar active_tab={@active_tab} current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar"/>

      <div class="flex flex-col flex-1">
        <!-- Headbar -->
        <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

        <!-- Main Content -->
        <main class="flex-1 overflow-y-auto pt-20 p-6 transition-all duration-300 bg-gray-100">

          <!-- Header Section -->
          <section class="mb-4">
            <h1 class="text-xl font-bold mb-1">Jabatan</h1>
            <p class="text-md text-gray-500 mb-4">Semak dan urus semua jabatan dalam sistem</p>
          </section>

          <!-- Top Section: Stats Cards -->
          <section class="mb-4">
            <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              <%= for {label, value} <- [{"Jumlah Jabatan", @stats.total_departments},
                                         {"Jabatan Aktif", @stats.active_departments},
                                         {"Jabatan Tidak Aktif", @stats.inactive_departments},
                                         {"Jumlah Staf", @stats.total_staff}] do %>
                <% number_color =
                  case label do
                    "Jumlah Jabatan" -> "text-gray-700"
                    "Jabatan Aktif" -> "text-green-500"
                    "Jabatan Tidak Aktif" -> "text-red-500"
                    "Jumlah Staf" -> "text-blue-500"
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

          <!-- Middle Section: Add Department Button -->
          <section class="mb-4 flex justify-end">
            <.link
              patch={~p"/admin/departments/new"}
              class="inline-flex items-center justify-center rounded-md border border-transparent bg-gray-900 px-4 py-2 text-sm font-semibold text-white hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-800 focus:ring-offset-2"
            >
              Tambah Jabatan
            </.link>
          </section>

          <!-- Bottom Section: Department Table -->
          <section class="bg-white p-4 md:p-6 rounded-xl shadow-md">
            <div class="flex items-center justify-between mb-4">
              <h2 class="text-lg font-semibold text-gray-900">Senarai Jabatan</h2>
            </div>

            <.table
              id="departments"
              rows={@streams.departments}
              row_click={fn {_id, dept} -> JS.patch(~p"/admin/departments/#{dept}?action=show") end}
            >
              <:col :let={{_id, dept}} label="ID">{dept.id}</:col>
              <:col :let={{_id, dept}} label="Nama Jabatan">{dept.name}</:col>
              <:col :let={{_id, dept}} label="Kod Jabatan">{dept.code}</:col>
              <:col :let={{_id, dept}} label="Pengurus Jabatan">{dept.head_manager}</:col>
              <:col :let={{_id, dept}} label="Lokasi Jabatan">{dept.location}</:col>
              <:col :let={{_id, dept}} label="Deskripsi Jabatan">{dept.description}</:col>
              <:col :let={{_id, dept}} label="Bil. Staf">
                <%= Map.get(@dept_counts, dept.id, 0) %>
              </:col>

              <:action :let={{_id, dept}}>
                <.link patch={~p"/admin/departments/#{dept}/edit"}>Edit</.link>
              </:action>
              <:action :let={{id, dept}}>
                <.link
                  phx-click={JS.push("delete", value: %{id: dept.id}) |> hide("##{id}")}
                  data-confirm="Anda yakin?"
                >
                  Padam
                </.link>
              </:action>
            </.table>
          </section>

          <!-- Modals -->
          <.modal :if={@live_action in [:new, :edit]} id="department-form-modal" show on_cancel={JS.patch(~p"/admin/departments")}>
            <.live_component
              module={FormComponent}
              id={@department.id || :new}
              title={@page_title}
              action={@live_action}
              department={@department}
              patch={~p"/admin/departments"}
            />
          </.modal>

          <.modal :if={@live_action == :show} id="department-show-modal" show on_cancel={JS.patch(~p"/admin/departments")}>
            <.live_component
              module={ShowComponent}
              id={@department.id}
              department={@department}
            />
          </.modal>

        </main>
      </div>
    </div>
    """
  end
end

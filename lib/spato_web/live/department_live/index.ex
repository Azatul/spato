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
     |> stream(:departments, Accounts.list_departments())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # Modal actions
  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Jabatan Baru")
    |> assign(:department, %Department{})
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
    {:noreply, stream_delete(socket, :departments, department)}
  end

  # Toggle sidebar
  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, update(socket, :sidebar_open, &(!&1))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen overflow-hidden">
      <!-- Sidebar -->
      <.sidebar
        active_tab={@active_tab}
        current_user={@current_user}
        open={@sidebar_open}
        toggle_event="toggle_sidebar"
      />
      <.headbar current_user={@current_user} open={@sidebar_open} toggle_event="toggle_sidebar" title={@page_title} />

      <!-- Main content -->
       <main class="flex-1 pt-16 p-6 transition-all duration-300 overflow-y-auto">
        <div class="bg-gray-100 p-4 md:p-8 rounded-lg">
          <h1 class="text-xl font-bold mb-1">Urus Jabatan</h1>
          <p class="text-md text-gray-500 mb-6">Semak dan urus semua jabatan dalam sistem</p>

          <!-- Header -->
          <header class="flex items-center justify-between mb-4">
            <h1 class="text-xl font-semibold leading-7 text-gray-900">Senarai Jabatan</h1>
            <div class="flex items-center gap-x-3">
              <.link patch={~p"/admin/departments/new"} class="inline-flex items-center justify-center rounded-md border border-transparent bg-gray-900 px-4 py-2 text-sm font-semibold leading-6 text-white transition duration-150 ease-in-out hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-800 focus:ring-offset-2">
                Tambah Jabatan
              </.link>
            </div>
          </header>

          <!-- Table -->
          <.table
            id="departments"
            rows={@streams.departments}
            row_click={fn {_id, dept} -> JS.patch(~p"/admin/departments/#{dept}?action=show") end}
          >
            <:col :let={{_id, dept}} label="Nama Jabatan">{dept.name}</:col>
            <:col :let={{_id, dept}} label="Kod Jabatan">{dept.code}</:col>
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

          <!-- Form Modal (New/Edit) -->
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

          <!-- Show Modal (Read-only) -->
          <.modal :if={@live_action == :show} id="department-show-modal" show on_cancel={JS.patch(~p"/admin/departments")}>
            <.live_component
              module={ShowComponent}
              id={@department.id}
              department={@department}
            />
          </.modal>

        </div>
      </main>
    </div>
    """
  end
end

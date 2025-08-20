defmodule SpatoWeb.DepartmentLive.Index do
  use SpatoWeb, :live_view

  alias Spato.Accounts
  alias Spato.Accounts.Department
  alias SpatoWeb.DepartmentLive.{FormComponent, ShowComponent}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :departments, Accounts.list_departments())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # Handle modal actions
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

  # Render
  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex justify-center items-start min-h-screen bg-gray-100 p-6">
      <div class="w-full max-w-4xl bg-white p-6 rounded-lg shadow-md">

        <.header>
          Senarai Jabatan
          <:actions>
            <.link patch={~p"/admin/departments/new"}><.button>Tambah Jabatan</.button></.link>
          </:actions>
        </.header>

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
              Delete
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
    </div>
    """
  end
end

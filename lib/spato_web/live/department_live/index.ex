defmodule SpatoWeb.DepartmentLive.Index do
  use SpatoWeb, :live_view

  alias Spato.Accounts
  alias Spato.Accounts.Department

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :departments, Accounts.list_departments())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Department")
    |> assign(:department, Accounts.get_department!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Department")
    |> assign(:department, %Department{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Departments")
    |> assign(:department, nil)
  end

  @impl true
  def handle_info({SpatoWeb.DepartmentLive.FormComponent, {:saved, department}}, socket) do
    {:noreply, stream_insert(socket, :departments, department)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    department = Accounts.get_department!(id)
    {:ok, _} = Accounts.delete_department(department)

    {:noreply, stream_delete(socket, :departments, department)}
  end
end

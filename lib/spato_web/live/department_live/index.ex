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

def render(assigns) do
  ~H"""
  <.header>
  Listing Departments
  <:actions>
    <.link patch={~p"/departments/new"}>
      <.button>New Department</.button>
    </.link>
  </:actions>
</.header>

<.table
  id="departments"
  rows={@streams.departments}
  row_click={fn {_id, department} -> JS.navigate(~p"/departments/#{department}") end}
>
  <:col :let={{_id, department}} label="Name">{department.name}</:col>
  <:col :let={{_id, department}} label="Code">{department.code}</:col>
  <:action :let={{_id, department}}>
    <div class="sr-only">
      <.link navigate={~p"/departments/#{department}"}>Show</.link>
    </div>
    <.link patch={~p"/departments/#{department}/edit"}>Edit</.link>
  </:action>
  <:action :let={{id, department}}>
    <.link
      phx-click={JS.push("delete", value: %{id: department.id}) |> hide("##{id}")}
      data-confirm="Are you sure?"
    >
      Delete
    </.link>
  </:action>
</.table>

<.modal :if={@live_action in [:new, :edit]} id="department-modal" show on_cancel={JS.patch(~p"/departments")}>
  <.live_component
    module={SpatoWeb.DepartmentLive.FormComponent}
    id={@department.id || :new}
    title={@page_title}
    action={@live_action}
    department={@department}
    patch={~p"/departments"}
  />
</.modal>
"""
 end
end

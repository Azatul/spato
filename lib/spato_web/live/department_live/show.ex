defmodule SpatoWeb.DepartmentLive.Show do
  use SpatoWeb, :live_view

  alias Spato.Accounts

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:department, Accounts.get_department!(id))}
  end

  defp page_title(:show), do: "Show Department"
  defp page_title(:edit), do: "Edit Department"

  @impl true
  def render(assigns) do
    ~H"""
<.header>
  Department {@department.id}
  <:subtitle>This is a department record from your database.</:subtitle>
  <:actions>
    <.link patch={~p"/departments/#{@department}/show/edit"} phx-click={JS.push_focus()}>
      <.button>Edit department</.button>
    </.link>
  </:actions>
</.header>

<.list>
  <:item title="Name">{@department.name}</:item>
  <:item title="Code">{@department.code}</:item>
</.list>

<.back navigate={~p"/departments"}>Back to departments</.back>

<.modal :if={@live_action == :edit} id="department-modal" show on_cancel={JS.patch(~p"/departments/#{@department}")}>
  <.live_component
    module={SpatoWeb.DepartmentLive.FormComponent}
    id={@department.id}
    title={@page_title}
    action={@live_action}
    department={@department}
    patch={~p"/departments/#{@department}"}
  />
</.modal>
"""
  end
end

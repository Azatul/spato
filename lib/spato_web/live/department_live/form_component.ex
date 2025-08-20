defmodule SpatoWeb.DepartmentLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"department-form-#{@id}"} class="p-4">
      <.header>{@title}<:subtitle>Urus jabatan dalam sistem.</:subtitle></.header>

      <.simple_form
        for={@form}
        id="department-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Nama" />
        <.input field={@form[:code]} type="text" label="Kod" />
        <:actions>
          <.button phx-disable-with="Saving...">Simpan</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{department: department} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn -> to_form(Accounts.change_department(department)) end)}
  end

  @impl true
  def handle_event("validate", %{"department" => params}, socket) do
    changeset = Accounts.change_department(socket.assigns.department, params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"department" => params}, socket) do
    save_department(socket, socket.assigns.action, params)
  end

  defp save_department(socket, :edit, params) do
    case Accounts.update_department(socket.assigns.department, params) do
      {:ok, dept} ->
        send(self(), {__MODULE__, {:saved, dept}})
        {:noreply, push_patch(socket, to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_department(socket, :new, params) do
    case Accounts.create_department(params) do
      {:ok, dept} ->
        send(self(), {__MODULE__, {:saved, dept}})
        {:noreply, push_patch(socket, to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end

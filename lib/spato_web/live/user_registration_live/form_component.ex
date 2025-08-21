defmodule SpatoWeb.UserRegistrationLive.FormComponent do
  use SpatoWeb, :live_component
  alias Spato.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"user-form-#{@id}"} class="p-4">
      <.header>{@title}<:subtitle>Daftar pengguna baru dalam sistem.</:subtitle></.header>

      <.simple_form
        for={@form}
        id="user-registration-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:email]} type="email" label="Emel" required />
        <.input field={@form[:password]} type="password" label="Katalaluan" required />
        <.input field={@form[:role]} type="select" label="Peranan" options={@roles} required />

        <:actions>
          <.button phx-disable-with="Mencipta pengguna...">Daftar</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Accounts.change_user_registration(user))
     end)}
  end

  @impl true
  def handle_event("validate", %{"user" => params}, socket) do
    changeset =
      Accounts.change_user_registration(socket.assigns.user, params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"user" => params}, socket) do
    case Accounts.register_user(params) do
      {:ok, user} ->
        send(self(), {__MODULE__, {:saved, user}})
        {:noreply, push_patch(socket, to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user(socket, :new, params) do
    case Accounts.register_user(params) do
      {:ok, user} ->
        send(self(), {__MODULE__, {:saved, user}})
        {:noreply,
         socket
         |> push_event("close_modal", %{})}  # <- trigger JS to hide modal

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset), check_errors: true)}
    end
  end

end

defmodule SpatoWeb.CateringMenuLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Assets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage catering_menu records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="catering_menu-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:type]} type="text" label="Type" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:price_per_head]} type="number" label="Price per head" step="any" />
        <.input field={@form[:photo_url]} type="text" label="Photo url" />
        <.input field={@form[:status]} type="text" label="Status" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Catering menu</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{catering_menu: catering_menu} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Assets.change_catering_menu(catering_menu))
     end)}
  end

  @impl true
  def handle_event("validate", %{"catering_menu" => catering_menu_params}, socket) do
    changeset = Assets.change_catering_menu(socket.assigns.catering_menu, catering_menu_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"catering_menu" => catering_menu_params}, socket) do
    save_catering_menu(socket, socket.assigns.action, catering_menu_params)
  end

  defp save_catering_menu(socket, :edit, catering_menu_params) do
    case Assets.update_catering_menu(socket.assigns.catering_menu, catering_menu_params) do
      {:ok, catering_menu} ->
        notify_parent({:saved, catering_menu})

        {:noreply,
         socket
         |> put_flash(:info, "Catering menu updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_catering_menu(socket, :new, catering_menu_params) do
    case Assets.create_catering_menu(catering_menu_params) do
      {:ok, catering_menu} ->
        notify_parent({:saved, catering_menu})

        {:noreply,
         socket
         |> put_flash(:info, "Catering menu created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

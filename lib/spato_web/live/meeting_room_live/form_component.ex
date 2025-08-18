defmodule SpatoWeb.MeetingRoomLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Facilities

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage meeting_room records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="meeting_room-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:capacity]} type="number" label="Capacity" />
        <.input field={@form[:availability]} type="text" label="Availability" />
        <.input field={@form[:status]} type="text" label="Status" />
        <.input field={@form[:features]} type="text" label="Features" />
        <.input field={@form[:image_url]} type="text" label="Image url" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Meeting room</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{meeting_room: meeting_room} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Facilities.change_meeting_room(meeting_room))
     end)}
  end

  @impl true
  def handle_event("validate", %{"meeting_room" => meeting_room_params}, socket) do
    changeset = Facilities.change_meeting_room(socket.assigns.meeting_room, meeting_room_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"meeting_room" => meeting_room_params}, socket) do
    save_meeting_room(socket, socket.assigns.action, meeting_room_params)
  end

  defp save_meeting_room(socket, :edit, meeting_room_params) do
    case Facilities.update_meeting_room(socket.assigns.meeting_room, meeting_room_params) do
      {:ok, meeting_room} ->
        notify_parent({:saved, meeting_room})

        {:noreply,
         socket
         |> put_flash(:info, "Meeting room updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_meeting_room(socket, :new, meeting_room_params) do
    case Facilities.create_meeting_room(meeting_room_params) do
      {:ok, meeting_room} ->
        notify_parent({:saved, meeting_room})

        {:noreply,
         socket
         |> put_flash(:info, "Meeting room created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

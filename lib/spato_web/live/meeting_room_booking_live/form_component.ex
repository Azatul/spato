defmodule SpatoWeb.MeetingRoomBookingLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Bookings

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage meeting_room_booking records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="meeting_room_booking-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:purpose]} type="text" label="Purpose" />
        <.input field={@form[:participants]} type="number" label="Participants" />
        <.input field={@form[:start_time]} type="datetime-local" label="Start time" />
        <.input field={@form[:end_time]} type="datetime-local" label="End time" />
        <.input field={@form[:is_recurring]} type="checkbox" label="Is recurring" />
        <.input field={@form[:recurrence_pattern]} type="text" label="Recurrence pattern" />
        <.input field={@form[:status]} type="text" label="Status" />
        <.input field={@form[:notes]} type="text" label="Notes" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Meeting room booking</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{meeting_room_booking: meeting_room_booking} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Bookings.change_meeting_room_booking(meeting_room_booking))
     end)}
  end

  @impl true
  def handle_event("validate", %{"meeting_room_booking" => meeting_room_booking_params}, socket) do
    changeset = Bookings.change_meeting_room_booking(socket.assigns.meeting_room_booking, meeting_room_booking_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"meeting_room_booking" => meeting_room_booking_params}, socket) do
    save_meeting_room_booking(socket, socket.assigns.action, meeting_room_booking_params)
  end

  defp save_meeting_room_booking(socket, :edit, meeting_room_booking_params) do
    case Bookings.update_meeting_room_booking(socket.assigns.meeting_room_booking, meeting_room_booking_params) do
      {:ok, meeting_room_booking} ->
        notify_parent({:saved, meeting_room_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Meeting room booking updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_meeting_room_booking(socket, :new, meeting_room_booking_params) do
    case Bookings.create_meeting_room_booking(meeting_room_booking_params) do
      {:ok, meeting_room_booking} ->
        notify_parent({:saved, meeting_room_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Meeting room booking created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

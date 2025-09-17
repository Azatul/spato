defmodule SpatoWeb.EquipmentBookingLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Bookings

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage equipment_booking records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="equipment_booking-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:quantity]} type="number" label="Quantity" />
        <.input field={@form[:location]} type="text" label="Location" />
        <.input field={@form[:usage_date]} type="date" label="Usage date" />
        <.input field={@form[:return_date]} type="date" label="Return date" />
        <.input field={@form[:usage_time]} type="time" label="Usage time" />
        <.input field={@form[:return_time]} type="time" label="Return time" />
        <.input field={@form[:additional_notes]} type="text" label="Additional notes" />
        <.input field={@form[:condition_before]} type="text" label="Condition before" />
        <.input field={@form[:condition_after]} type="text" label="Condition after" />
        <.input field={@form[:status]} type="text" label="Status" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Equipment booking</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{equipment_booking: equipment_booking} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Bookings.change_equipment_booking(equipment_booking))
     end)}
  end

  @impl true
  def handle_event("validate", %{"equipment_booking" => equipment_booking_params}, socket) do
    changeset = Bookings.change_equipment_booking(socket.assigns.equipment_booking, equipment_booking_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"equipment_booking" => equipment_booking_params}, socket) do
    save_equipment_booking(socket, socket.assigns.action, equipment_booking_params)
  end

  defp save_equipment_booking(socket, :edit, equipment_booking_params) do
    case Bookings.update_equipment_booking(socket.assigns.equipment_booking, equipment_booking_params) do
      {:ok, equipment_booking} ->
        notify_parent({:saved, equipment_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Equipment booking updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_equipment_booking(socket, :new, equipment_booking_params) do
    case Bookings.create_equipment_booking(equipment_booking_params) do
      {:ok, equipment_booking} ->
        notify_parent({:saved, equipment_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Equipment booking created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

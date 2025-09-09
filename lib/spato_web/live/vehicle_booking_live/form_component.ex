defmodule SpatoWeb.VehicleBookingLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Bookings

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage vehicle_booking records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="vehicle_booking-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:purpose]} type="text" label="Purpose" />
        <.input field={@form[:trip_destination]} type="text" label="Trip destination" />
        <.input field={@form[:pickup_time]} type="datetime-local" label="Pickup time" />
        <.input field={@form[:return_time]} type="datetime-local" label="Return time" />
        <.input field={@form[:additional_notes]} type="text" label="Additional notes" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Vehicle booking</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{vehicle_booking: vehicle_booking} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Bookings.change_vehicle_booking(vehicle_booking))
     end)}
  end

  @impl true
  def handle_event("validate", %{"vehicle_booking" => vehicle_booking_params}, socket) do
    changeset = Bookings.change_vehicle_booking(socket.assigns.vehicle_booking, vehicle_booking_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"vehicle_booking" => vehicle_booking_params}, socket) do
    save_vehicle_booking(socket, socket.assigns.action, vehicle_booking_params)
  end

  defp save_vehicle_booking(socket, :edit, vehicle_booking_params) do
    case Bookings.update_vehicle_booking(socket.assigns.vehicle_booking, vehicle_booking_params) do
      {:ok, vehicle_booking} ->
        notify_parent({:saved, vehicle_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Vehicle booking updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_vehicle_booking(socket, :new, vehicle_booking_params) do
    case Bookings.create_vehicle_booking(vehicle_booking_params) do
      {:ok, vehicle_booking} ->
        notify_parent({:saved, vehicle_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Vehicle booking created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

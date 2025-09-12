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
         <!-- Vehicle info (readonly, prefilled) -->
      <%= if @vehicle do %>
        <.input field={@form[:vehicle_model]} label="Model" readonly />
        <.input field={@form[:plate_number]} label="No. Plat" readonly />
        <.input field={@form[:capacity]} label="Kapasiti" readonly />
        <.input field={@form[:status]} label="Status" readonly />
      <% end %>

      <!-- Prefilled times -->
      <.input field={@form[:pickup_time]} type="datetime-local" label="Pickup time" />
      <.input field={@form[:return_time]} type="datetime-local" label="Return time" />

      <!-- Other fields -->
      <.input field={@form[:purpose]} type="text" label="Purpose" />
      <.input field={@form[:trip_destination]} type="text" label="Trip destination" />
      <.input field={@form[:additional_notes]} type="text" label="Additional notes" />

      <!-- Save button -->
        <:actions>
          <.button phx-disable-with="Saving...">
            <%= if @action == :new do %>
              Simpan Tempahan Kenderaan
            <% else %>
              Kemaskini Tempahan Kenderaan
            <% end %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{vehicle_booking: vehicle_booking, params: params} = assigns, socket) do
    vehicle =
      case params["vehicle_id"] do
        nil -> nil
        id -> Spato.Repo.get!(Spato.Assets.Vehicle, id)
      end

    changeset =
      Bookings.change_vehicle_booking(vehicle_booking, %{
        vehicle_id: vehicle && vehicle.id,
        vehicle_model: vehicle && vehicle.vehicle_model,
        plate_number: vehicle && vehicle.plate_number,
        capacity: vehicle && vehicle.capacity,
        status: vehicle && vehicle.status,
        pickup_time: params["pickup_time"],
        return_time: params["return_time"]
      })

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:vehicle, vehicle)
     |> assign(:form, to_form(changeset))}
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
    params =
      vehicle_booking_params
      |> Map.put_new("user_id", socket.assigns.current_user.id)

    case Bookings.create_vehicle_booking(params) do
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

defmodule SpatoWeb.AdminVehicleBookingLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Bookings

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Gunakan borang ini untuk menguruskan tempahan kenderaan.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="vehicle_booking-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:purpose]} type="text" label="Tujuan" />
        <.input field={@form[:trip_destination]} type="text" label="Destinasi Perjalanan" />
        <.input field={@form[:pickup_time]} type="datetime-local" label="Masa Ambil" />
        <.input field={@form[:return_time]} type="datetime-local" label="Masa Pulang" />
        <.input field={@form[:status]} type="select" label="Status" options={status_options()} />
        <.input field={@form[:additional_notes]} type="textarea" label="Nota Tambahan" />
        <.input field={@form[:rejection_reason]} type="textarea" label="Sebab Penolakan" />
        <:actions>
          <.button phx-disable-with="Menyimpan...">Simpan Perubahan</.button>
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
    # Add approved_by_user_id if status is being changed to approved/rejected
    updated_params =
      if vehicle_booking_params["status"] in ["approved", "rejected"] do
        Map.put(vehicle_booking_params, "approved_by_user_id", socket.assigns.current_user.id)
      else
        vehicle_booking_params
      end

    case Bookings.update_vehicle_booking(socket.assigns.vehicle_booking, updated_params) do
      {:ok, vehicle_booking} ->
        notify_parent({:saved, vehicle_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Tempahan kenderaan berjaya dikemaskini")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_vehicle_booking(socket, :new, vehicle_booking_params) do
    # Add user_id and set default status to pending
    booking_params =
      vehicle_booking_params
      |> Map.put("user_id", socket.assigns.current_user.id)
      |> Map.put("status", "pending")

    case Bookings.create_vehicle_booking(booking_params) do
      {:ok, vehicle_booking} ->
        notify_parent({:saved, vehicle_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Tempahan kenderaan berjaya dibuat")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp status_options do
    [
      {"Menunggu", "pending"},
      {"Diluluskan", "approved"},
      {"Ditolak", "rejected"},
      {"Dibatalkan", "cancelled"},
      {"Selesai", "completed"}
    ]
  end
end

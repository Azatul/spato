defmodule SpatoWeb.VehicleBookingLive.FormComponent do
  use SpatoWeb, :live_component
  alias Spato.Bookings

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-xl mx-auto bg-white p-6 rounded-xl shadow-md">
      <.header>
        {@title}
        <:subtitle>Sila isi butiran untuk menempah kenderaan.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="vehicle_booking-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <!-- Preloaded fields -->
        <.input field={@form[:vehicle_id]} type="hidden" />
        <.input field={@form[:pickup_time]} type="datetime-local" label="Masa Ambil" />
        <.input field={@form[:return_time]} type="datetime-local" label="Masa Pulang" />

        <!-- User-filled fields -->
        <.input field={@form[:purpose]} type="text" label="Tujuan" />
        <.input field={@form[:trip_destination]} type="text" label="Destinasi" />
        <.input field={@form[:additional_notes]} type="text" label="Nota tambahan" />

        <:actions>
          <.button phx-disable-with="Menyimpan..." class="bg-blue-600 text-white">
            Simpan Tempahan
          </.button>
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
  def handle_event("validate", %{"vehicle_booking" => params}, socket) do
    changeset =
      Bookings.change_vehicle_booking(socket.assigns.vehicle_booking, params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"vehicle_booking" => params}, socket) do
    save_vehicle_booking(socket, socket.assigns.action, params)
  end

  defp save_vehicle_booking(socket, :edit, params) do
    case Bookings.update_vehicle_booking(socket.assigns.vehicle_booking, params) do
      {:ok, vehicle_booking} ->
        notify_parent({:saved, vehicle_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Tempahan dikemas kini")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_vehicle_booking(socket, :new, params) do
    params =
      params
      |> Map.put_new("user_id", socket.assigns.current_user.id)

    case Bookings.create_vehicle_booking(params) do
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
end

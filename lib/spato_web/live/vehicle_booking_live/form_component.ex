defmodule SpatoWeb.VehicleBookingLive.FormComponent do
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
        <!-- Vehicle info (readonly, prefilled if chosen) -->
        <%= if @vehicle do %>
          <.input field={@form[:vehicle_model]} label="Model" readonly />
          <.input field={@form[:plate_number]} label="No. Plat" readonly />
          <.input field={@form[:capacity]} label="Kapasiti" readonly />
        <% end %>

        <!-- Prefilled times -->
        <.input field={@form[:pickup_time]} type="datetime-local" label="Masa Ambil" />
        <.input field={@form[:return_time]} type="datetime-local" label="Masa Pulang" />

        <!-- Other fields -->
        <.input field={@form[:purpose]} type="text" label="Tujuan" />
        <.input field={@form[:trip_destination]} type="text" label="Destinasi" />
        <.input field={@form[:additional_notes]} type="text" label="Catatan Tambahan" />

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

  # Single update/2 handling both new/edit
  @impl true
  def update(%{vehicle_booking: vehicle_booking, params: params} = assigns, socket) do
    # Load vehicle if vehicle_id passed
    vehicle =
      case params["vehicle_id"] do
        nil -> nil
        id -> Spato.Repo.get!(Spato.Assets.Vehicle, id)
      end

    # Normalize times (treat "" as nil)
    attrs =
      params
      |> Map.take(["vehicle_id", "pickup_time", "return_time"])
      |> Enum.reduce(%{}, fn
        {"pickup_time", ""}, acc -> Map.put(acc, "pickup_time", nil)
        {"return_time", ""}, acc -> Map.put(acc, "return_time", nil)
        {k, v}, acc -> Map.put(acc, k, v)
      end)

    # Merge in vehicle details if available
    attrs =
      if vehicle do
        Map.merge(attrs, %{
          "vehicle_id" => vehicle.id,
          "vehicle_model" => vehicle.vehicle_model,
          "plate_number" => vehicle.plate_number,
          "capacity" => vehicle.capacity,
          "status" => vehicle.status
        })
      else
        attrs
      end

    # Build changeset
    changeset = Bookings.change_vehicle_booking(vehicle_booking, attrs)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:vehicle, vehicle)
     |> assign(:form, to_form(changeset))}
  end

  # Live validation
  @impl true
  def handle_event("validate", %{"vehicle_booking" => vehicle_booking_params}, socket) do
    changeset =
      Bookings.change_vehicle_booking(socket.assigns.vehicle_booking, vehicle_booking_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  # Save booking
  @impl true
  def handle_event("save", %{"vehicle_booking" => vehicle_booking_params}, socket) do
    save_vehicle_booking(socket, socket.assigns.action, vehicle_booking_params)
  end

  defp save_vehicle_booking(socket, :edit, vehicle_booking_params) do
    case Bookings.update_vehicle_booking(socket.assigns.vehicle_booking, vehicle_booking_params) do
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
    params =
      vehicle_booking_params
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

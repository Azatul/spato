defmodule SpatoWeb.VehicleBookingLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Bookings
  alias Spato.Assets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Gunakan borang ini untuk membuat tempahan kenderaan.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="vehicle_booking-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <!-- Vehicle Selection -->
        <%= if @selected_vehicle do %>
          <!-- Show selected vehicle info -->
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-2">Kenderaan Dipilih</label>
            <div class="p-3 border border-gray-200 rounded-lg bg-gray-50">
              <div class="flex items-center space-x-3">
                <img src={@selected_vehicle.photo_url || "/images/placeholder-vehicle.jpg"} class="w-12 h-12 object-cover rounded-lg" />
                <div>
                  <div class="font-medium text-gray-900"><%= @selected_vehicle.name %></div>
                  <div class="text-sm text-gray-500"><%= @selected_vehicle.plate_number %></div>
                  <div class="text-xs text-gray-400"><%= @selected_vehicle.type %> • <%= @selected_vehicle.capacity %> penumpang</div>
                </div>
              </div>
            </div>
            <!-- Hidden input to pass vehicle_id -->
            <input type="hidden" name="vehicle_booking[vehicle_id]" value={@selected_vehicle.id} />
          </div>
        <% else %>
          <!-- Show vehicle selection based on dates -->
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-2">Pilih Kenderaan</label>
            <%= if Enum.empty?(@filtered_vehicles) do %>
              <div class="text-gray-500 text-sm p-4 border border-gray-200 rounded-md bg-gray-50">
                <%= if @form[:pickup_time].value && @form[:return_time].value do %>
                  Tiada kenderaan tersedia untuk tempoh masa yang dipilih. Sila pilih masa yang berbeza.
                <% else %>
                  Sila pilih masa ambil dan masa pulang untuk melihat kenderaan yang tersedia.
                <% end %>
              </div>
            <% else %>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3 max-h-60 overflow-y-auto">
                <%= for vehicle <- @filtered_vehicles do %>
                  <label class="flex items-center p-3 border border-gray-200 rounded-lg cursor-pointer hover:bg-gray-50 transition-colors">
                    <input
                      type="radio"
                      name="vehicle_booking[vehicle_id]"
                      value={vehicle.id}
                      class="mr-3"
                      checked={@form[:vehicle_id].value == vehicle.id}
                    />
                    <div class="flex-1">
                      <div class="font-medium text-gray-900"><%= vehicle.name %></div>
                      <div class="text-sm text-gray-500"><%= vehicle.plate_number %></div>
                      <div class="text-xs text-gray-400"><%= vehicle.type %> • <%= vehicle.capacity %> penumpang</div>
                    </div>
                  </label>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>

        <.input field={@form[:purpose]} type="text" label="Tujuan" placeholder="e.g. Meeting dengan pelanggan" />
        <.input field={@form[:trip_destination]} type="text" label="Destinasi Perjalanan" placeholder="e.g. Kuala Lumpur" />
        <.input field={@form[:pickup_time]} type="datetime-local" label="Masa Ambil" />
        <.input field={@form[:return_time]} type="datetime-local" label="Masa Pulang" />
        <.input field={@form[:additional_notes]} type="textarea" label="Nota Tambahan" placeholder="Maklumat tambahan jika ada" />
        <:actions>
          <.button phx-disable-with="Menyimpan...">Simpan Tempahan</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{vehicle_booking: vehicle_booking} = assigns, socket) do
    vehicle_options = get_vehicle_options()

    # Get vehicle details if vehicle_id is pre-filled
    selected_vehicle = if vehicle_booking.vehicle_id do
      Assets.get_vehicle!(vehicle_booking.vehicle_id)
    else
      Map.get(assigns, :selected_vehicle, nil)
    end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:vehicle_options, vehicle_options)
     |> assign(:selected_vehicle, selected_vehicle)
     |> assign(:filtered_vehicles, [])
     |> assign_new(:form, fn ->
       to_form(Bookings.change_vehicle_booking(vehicle_booking))
     end)}
  end

  @impl true
  def handle_event("validate", %{"vehicle_booking" => vehicle_booking_params}, socket) do
    changeset = Bookings.change_vehicle_booking(socket.assigns.vehicle_booking, vehicle_booking_params)

    # Filter vehicles based on selected dates
    filtered_vehicles = filter_vehicles_by_dates(vehicle_booking_params)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset, action: :validate))
     |> assign(:filtered_vehicles, filtered_vehicles)}
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

  defp get_vehicle_options do
    Assets.list_vehicles()
    |> Enum.filter(fn vehicle -> vehicle.status == "tersedia" end)
    |> Enum.map(fn vehicle ->
      {"#{vehicle.name} (#{vehicle.plate_number}) - #{vehicle.type}", vehicle.id}
    end)
  end

  defp filter_vehicles_by_dates(params) do
    pickup_time = Map.get(params, "pickup_time")
    return_time = Map.get(params, "return_time")

    if pickup_time && return_time do
      # Use the same filtering logic as available_vehicles_paginated
      filter_params = %{
        "pickup_time" => pickup_time,
        "return_time" => return_time
      }

      # Get available vehicles for the selected time period
      data = Spato.Bookings.available_vehicles_paginated(filter_params)
      data.vehicles_page
    else
      []
    end
  end
end

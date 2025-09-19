defmodule SpatoWeb.EquipmentBookingLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Bookings

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Gunakan borang ini untuk menguruskan tempahan peralatan.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="equipment_booking-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <!-- Equipment info (readonly if chosen) -->
        <%= if @equipment do %>
          <.input field={@form[:equipment_name]} label="Nama Peralatan" readonly />
          <.input field={@form[:serial_number]} label="No. Siri" readonly />
          <.input field={@form[:type]} label="Jenis" readonly />
          <.input field={@form[:quantity_available]} label="Kuantiti Tersedia" readonly />

          <!-- Hidden field -->
          <input type="hidden" name="equipment_booking[equipment_id]" value={@equipment.id} />
        <% end %>


        <!-- Prefilled times (readonly) -->
        <.input field={@form[:usage_date]} type="date" label="Tarikh Guna" readonly />
        <.input field={@form[:usage_time]} type="time" label="Masa Guna" readonly />
        <.input field={@form[:return_date]} type="date" label="Tarikh Pulang" readonly />
        <.input field={@form[:return_time]} type="time" label="Masa Pulang" readonly />

        <!-- User inputs -->
        <.input field={@form[:location]} type="text" label="Lokasi" />
        <.input
          field={@form[:quantity]}
          type="number"
          label="Kuantiti Diminta"
          min="1"
          max={if @equipment, do: @equipment.quantity_available, else: 100}
        />
        <.input field={@form[:additional_notes]} type="text" label="Catatan Tambahan" />

        <:actions>
          <.button phx-disable-with="Saving...">
            <%= if @action == :new do %>
              Hantar Tempahan
            <% else %>
              Kemaskini Tempahan Peralatan
            <% end %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{equipment_booking: equipment_booking, params: params} = assigns, socket) do
    equipment =
      case params["equipment_id"] do
        nil -> nil
        id -> Spato.Repo.get!(Spato.Assets.Equipment, id)
      end

    attrs =
      params
      |> Map.take([
        "equipment_id",
        "usage_date",
        "usage_time",
        "return_date",
        "return_time",
        "quantity"
      ])
      |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
      |> Map.new()

    attrs =
      if equipment do
        Map.merge(attrs, %{
          "equipment_name" => equipment.name,
          "serial_number" => equipment.serial_number,
          "type" => equipment.type,
          "quantity_available" => equipment.quantity_available,
          "quantity" => attrs["quantity"] || 1
        })
      else
        attrs
      end

    changeset = Bookings.change_equipment_booking(equipment_booking, attrs)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:equipment, equipment)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def update(%{equipment_booking: equipment_booking} = assigns, socket) do
    changeset = Bookings.change_equipment_booking(equipment_booking)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:equipment, nil)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"equipment_booking" => params}, socket) do
    changeset =
      Bookings.change_equipment_booking(socket.assigns.equipment_booking, params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"equipment_booking" => params}, socket) do
    save_equipment_booking(socket, socket.assigns.action, params)
  end

  defp save_equipment_booking(socket, :edit, params) do
    case Bookings.update_equipment_booking(socket.assigns.equipment_booking, params) do
      {:ok, equipment_booking} ->
        notify_parent({:saved, equipment_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Tempahan peralatan berjaya dikemaskini")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_equipment_booking(socket, :new, params) do
    params = Map.put_new(params, "user_id", socket.assigns.current_user.id)

    case Bookings.create_equipment_booking(params) do
      {:ok, equipment_booking} ->
        notify_parent({:saved, equipment_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Tempahan peralatan berjaya dibuat")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

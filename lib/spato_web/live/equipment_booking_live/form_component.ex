defmodule SpatoWeb.EquipmentBookingLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Bookings
  alias Spato.Assets.Equipment
  alias Spato.Repo

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

          <!-- Hidden field -->
          <input type="hidden" name="equipment_booking[equipment_id]" value={@equipment.id} />
        <% end %>

        <!-- Prefilled times (readonly) -->
        <.input field={@form[:usage_at]} type="datetime-local" label="Tarikh Guna" readonly />
        <.input field={@form[:return_at]} type="datetime-local" label="Tarikh Pulang" readonly />

        <!-- User inputs -->
        <.input field={@form[:location]} type="text" label="Lokasi" />
        <.input
          field={@form[:requested_quantity]}
          type="number"
          label="Kuantiti Diminta"
          min="1"
          max={if @equipment, do: @equipment.available_quantity, else: 100}
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
  def update(%{
      equipment_booking: equipment_booking,
      equipment_id: equipment_id,
      usage_at: usage_at,
      return_at: return_at,
      current_user: current_user
    } = assigns, socket) do

    equipment = if equipment_id, do: Repo.get(Equipment, equipment_id), else: nil

    # Compute available quantity for the selected window for max attribute and UX
    available_quantity =
      case {equipment, usage_at, return_at} do
        {nil, _, _} -> nil
        {_, nil, _} -> equipment && equipment.total_quantity
        {_, _, nil} -> equipment && equipment.total_quantity
        {%Equipment{} = eq, usage_at, return_at} ->
          import Ecto.Query
          alias Spato.Bookings.EquipmentBooking

          overlapping_q =
            from b in EquipmentBooking,
              where:
                b.equipment_id == ^eq.id and
                b.status in ["pending", "approved"] and
                b.usage_at < ^return_at and
                b.return_at > ^usage_at,
              select: sum(b.requested_quantity)

          (eq.total_quantity || 0) - (Repo.one(overlapping_q) || 0)
      end

    attrs =
      %{
        "equipment_id" => equipment_id,
        "usage_at" => usage_at,
        "return_at" => return_at
      }
      |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
      |> Map.new()
      |> maybe_merge_equipment(equipment)
      |> Map.merge(%{"available_quantity" => available_quantity})

    changeset = Bookings.change_equipment_booking(equipment_booking, attrs)

    {:ok,
    socket
    |> assign(assigns)
    |> assign(:equipment, equipment)
    |> assign(:form, to_form(changeset))
    |> assign(:current_user, current_user)}
    end

  defp maybe_merge_equipment(attrs, nil), do: attrs

  defp maybe_merge_equipment(attrs, %Equipment{} = equipment) do
    Map.merge(attrs, %{
      "equipment_name" => equipment.name,
      "serial_number" => equipment.serial_number,
      "type" => equipment.type,
      "available_quantity" => equipment.available_quantity,
      "total_quantity" => equipment.total_quantity,
      "requested_quantity" => attrs["requested_quantity"] || 1
    })
  end

  @impl true
  def handle_event("validate", %{"equipment_booking" => params}, socket) do
    changeset =
      socket.assigns.equipment_booking
      |> Bookings.change_equipment_booking(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"equipment_booking" => params}, socket) do
    params =
      params
      |> Map.put_new("user_id", socket.assigns.current_user.id)
      |> Map.put_new("status", "pending")

    case socket.assigns.action do
      :new -> save_new_booking(socket, params)
      :edit -> save_edit_booking(socket, params)
    end
  end

  defp save_new_booking(socket, params) do
    case Bookings.create_equipment_booking(params) do
      {:ok, booking} ->
        notify_parent({:saved, booking})

        {:noreply,
         socket
         |> put_flash(:info, "Tempahan peralatan berjaya dibuat")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_edit_booking(socket, params) do
    case Bookings.update_equipment_booking(socket.assigns.equipment_booking, params) do
      {:ok, booking} ->
        notify_parent({:saved, booking})

        {:noreply,
         socket
         |> put_flash(:info, "Tempahan peralatan berjaya dikemaskini")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

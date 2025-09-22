defmodule SpatoWeb.CateringBookingLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Bookings

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Gunakan borang ini untuk menguruskan tempahan katering.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="catering_booking-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <!-- Menu info (readonly, prefilled if chosen) -->
        <%= if @menu do %>
            <.input field={@form[:menu_name]} label="Nama Menu" readonly />
            <.input field={@form[:menu_description]} label="Penerangan Menu" readonly />
            <.input field={@form[:menu_type]} label="Jenis Menu" readonly />
            <.input field={@form[:price_per_head]} label="Harga Per Kepala" readonly />
            <input type="hidden" name="catering_booking[menu_id]" value={@menu.id} />
        <% end %>

        <!-- Prefilled date and time -->
        <.input field={@form[:date]} type="date" label="Tarikh" readonly />
        <.input field={@form[:time]} type="time" label="Masa" />

        <!-- Other fields -->
        <.input field={@form[:location]} type="text" label="Lokasi" />
        <.input field={@form[:special_request]} type="text" label="Permintaan Khusus" />

        <!-- Number of participants -->
        <.input
          field={@form[:participants]}
          type="number"
          label="Bilangan Peserta"
          min="1"
        />

        <:actions>
          <.button phx-disable-with="Saving...">
            <%= if @action == :new do %>
              Hantar Tempahan
            <% else %>
              Kemaskini Tempahan Katering
            <% end %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  # Single update/2 handling both new/edit
  @impl true
  def update(%{catering_booking: catering_booking, params: params} = assigns, socket) do
    # Load menu if menu_id passed
    menu =
      case params["menu_id"] do
        nil -> nil
        id -> Spato.Repo.get!(Spato.Assets.CateringMenu, id)
      end

    # Normalize date and time (treat "" as nil)
    attrs =
      params
      |> Map.take(["menu_id", "date", "time", "participants", "location", "special_request"])
      |> Enum.reduce(%{}, fn
        {"date", ""}, acc -> Map.put(acc, "date", nil)
        {"time", ""}, acc -> Map.put(acc, "time", nil)
        {k, v}, acc -> Map.put(acc, k, v)
      end)

    # Merge in menu details if available
    attrs =
      if menu do
        total_cost =
          case attrs["participants"] do
            nil -> Decimal.new("0.00")
            participants ->
              case Integer.parse(participants) do
                {num, _} -> Decimal.mult(menu.price_per_head, Decimal.new(num))
                _ -> Decimal.new("0.00")
              end
          end

        Map.merge(attrs, %{
          "menu_id" => menu.id,
          "menu_name" => menu.name,
          "menu_description" => menu.description,
          "menu_type" => Spato.Assets.CateringMenu.human_type(menu.type),
          "price_per_head" => "RM #{:erlang.float_to_binary(Decimal.to_float(menu.price_per_head), [decimals: 2])}",
          "total_cost" => total_cost,
          "status" => "pending"
        })
      else
        attrs
      end

    # Build changeset
    changeset = Bookings.change_catering_booking(catering_booking, attrs)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:menu, menu)
     |> assign(:form, to_form(changeset))}
  end

  # Live validation
  @impl true
  def handle_event("validate", %{"catering_booking" => catering_booking_params}, socket) do
    # Recalculate total cost if participants changed
    params =
      if socket.assigns.menu && catering_booking_params["participants"] do
        case Integer.parse(catering_booking_params["participants"]) do
          {num, _} ->
            total_cost = Decimal.mult(socket.assigns.menu.price_per_head, Decimal.new(num))
            Map.put(catering_booking_params, "total_cost", total_cost)
          _ ->
            catering_booking_params
        end
      else
        catering_booking_params
      end

    changeset =
      Bookings.change_catering_booking(socket.assigns.catering_booking, params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  # Save booking
  @impl true
  def handle_event("save", %{"catering_booking" => catering_booking_params}, socket) do
    save_catering_booking(socket, socket.assigns.action, catering_booking_params)
  end

  defp save_catering_booking(socket, :edit, catering_booking_params) do
    case Bookings.update_catering_booking(socket.assigns.catering_booking, catering_booking_params) do
      {:ok, catering_booking} ->
        notify_parent({:saved, catering_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Tempahan katering berjaya dikemaskini")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_catering_booking(socket, :new, catering_booking_params) do
    params =
      catering_booking_params
      |> Map.put_new("user_id", socket.assigns.current_user.id)

    case Bookings.create_catering_booking(params) do
      {:ok, catering_booking} ->
        notify_parent({:saved, catering_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Tempahan katering berjaya dibuat")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

defmodule SpatoWeb.MeetingRoomBookingLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Bookings

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Gunakan borang ini untuk menguruskan tempahan bilik mesyuarat.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="meeting_room_booking-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <!-- Meeting room info (readonly, prefilled if chosen) -->

        <%= if @meeting_room do %>
            <.input field={@form[:meeting_room_name]} label="Nama Bilik" readonly />
            <.input field={@form[:capacity]} label="Kapasiti" readonly />
            <.input field={@form[:location]} label="Lokasi" readonly />
            <.input field={@form[:equipment]} label="Peralatan" readonly />
            <input type="hidden" name="meeting_room_booking[meeting_room_id]" value={@meeting_room.id} />
        <% end %>

        <!-- Prefilled times -->
        <.input field={@form[:start_time]} type="datetime-local" label="Masa Mula" readonly />
        <.input field={@form[:end_time]} type="datetime-local" label="Masa Tamat" readonly />

        <!-- Other fields -->
        <.input field={@form[:purpose]} type="text" label="Tujuan" />
        <.input field={@form[:participants]} type="number" label="Bilangan Peserta" min="1" />
        <.input field={@form[:notes]} type="text" label="Catatan Tambahan" />

        <:actions>
          <.button phx-disable-with="Saving...">
            <%= if @action == :new do %>
              Hantar Tempahan
            <% else %>
              Kemaskini Tempahan Bilik Mesyuarat
            <% end %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  # Single update/2 handling both new/edit
  @impl true
def update(%{meeting_room_booking: meeting_room_booking} = assigns, socket) do
  params = Map.get(assigns, :params, %{}) # ambil params kalau ada, else kosong

  # Load meeting room jika ada
  meeting_room =
    case params["meeting_room_id"] || assigns[:meeting_room_id] do
      nil -> nil
      id -> Spato.Repo.get!(Spato.Assets.MeetingRoom, id)
    end

  # Normalize times
  attrs =
    params
    |> Map.take(["meeting_room_id", "start_time", "end_time"])
    |> Enum.reduce(%{}, fn
      {"start_time", ""}, acc -> Map.put(acc, "start_time", nil)
      {"end_time", ""}, acc -> Map.put(acc, "end_time", nil)
      {k, v}, acc -> Map.put(acc, k, v)
    end)

  # Merge in meeting room details jika ada
  attrs =
    if meeting_room do
      Map.merge(attrs, %{
        "meeting_room_id" => meeting_room.id,
        "meeting_room_name" => meeting_room.name,
        "capacity" => meeting_room.capacity,
        "location" => meeting_room.location,
        "equipment" => meeting_room.available_facility,
        "participants" => attrs["participants"] || 1
      })
    else
      attrs
    end

  changeset = Bookings.change_meeting_room_booking(meeting_room_booking, attrs)

  {:ok,
   socket
   |> assign(assigns)
   |> assign(:meeting_room, meeting_room)
   |> assign(:form, to_form(changeset))}
end


  # Live validation
  @impl true
  def handle_event("validate", %{"meeting_room_booking" => meeting_room_booking_params}, socket) do
    changeset =
      Bookings.change_meeting_room_booking(socket.assigns.meeting_room_booking, meeting_room_booking_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  # Save booking
  @impl true
  def handle_event("save", %{"meeting_room_booking" => meeting_room_booking_params}, socket) do
    save_meeting_room_booking(socket, socket.assigns.action, meeting_room_booking_params)
  end

  defp save_meeting_room_booking(socket, :edit, meeting_room_booking_params) do
    case Bookings.update_meeting_room_booking(socket.assigns.meeting_room_booking, meeting_room_booking_params) do
      {:ok, meeting_room_booking} ->
        notify_parent({:saved, meeting_room_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Tempahan bilik mesyuarat berjaya dikemaskini")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_meeting_room_booking(socket, :new, meeting_room_booking_params) do
    params =
      meeting_room_booking_params
      |> Map.put_new("user_id", socket.assigns.current_user.id)

    case Bookings.create_meeting_room_booking(params) do
      {:ok, meeting_room_booking} ->
        notify_parent({:saved, meeting_room_booking})

        {:noreply,
         socket
         |> put_flash(:info, "Tempahan bilik mesyuarat berjaya dibuat")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

defmodule SpatoWeb.VehicleLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Assets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Gunakan borang ini untuk menguruskan rekod kenderaan dalam sistem.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="vehicle-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <div class="text-sm font-medium text-gray-700">Gambar Kenderaan</div>
          <div class="relative w-40 h-40 rounded-md bg-gray-200 flex items-center justify-center overflow-hidden">
            <%= if Enum.any?(@uploads.vehicle_image.entries) do %>
              <%= for entry <- @uploads.vehicle_image.entries do %>
                <.live_img_preview entry={entry} class="object-cover w-full h-full rounded-md" />
              <% end %>
            <% else %>
              <%= if @vehicle_image_preview_url do %>
                <img src={@vehicle_image_preview_url} class="object-cover w-full h-full rounded-md" />
              <% else %>
                <img src="/images/default-image.jpg" class="object-cover w-full h-full rounded-md" />
              <% end %>
            <% end %>

            <div class="absolute bottom-2 left-1/2 -translate-x-1/2 flex space-x-2">
              <label class="bg-blue-500 text-white rounded-full p-2 cursor-pointer hover:bg-blue-600 transition-colors duration-200">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor"><path d="M13.586 3.586a2 2 0 112.828 2.828l-7.258 7.258a2 2 0 01-.715.42L6 14.12l-.39-.39a2 2 0 01.42-.715l7.258-7.258z" /></svg>
                <.live_file_input upload={@uploads.vehicle_image} class="sr-only" />
              </label>
              <button type="button" phx-target={@myself} phx-click="remove_vehicle_image" class="bg-red-500 text-white rounded-full p-2 hover:bg-red-600 transition-colors duration-200">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 011 1v6a1 1 0 11-2 0V8a1 1 0 011-1z" clip-rule="evenodd" /></svg>
              </button>
            </div>
          </div>
        </div>
        <.input field={@form[:name]} type="text" label="Nama Kenderaan" placeholder="e.g. Proton Saga" />
        <.input
          field={@form[:type]}
          type="select"
          label="Jenis"
          options={[
            {"Kereta", "kereta"},
            {"SUV / MPV", "mpv"},
            {"Pickup / 4WD", "pickup"},
            {"Van", "van"},
            {"Bas", "bas"},
            {"Motosikal", "motosikal"}
          ]}
          prompt="Pilih jenis kenderaan"
        />
        <.input field={@form[:vehicle_model]} type="text" label="Model" placeholder="e.g. Saga 1.3 Standard" />
        <.input field={@form[:plate_number]} type="text" label="Nombor Plat" placeholder="e.g. ABC1234" />
        <.input field={@form[:capacity]} type="number" label="Kapasiti Penumpang" placeholder="e.g. 4" />
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          options={[
            {"Tersedia", "tersedia"},
            {"Dalam Penyelenggaraan", "dalam_penyelenggaraan"}
          ]}
        />
        <.input field={@form[:last_services_at]} type="date" label="Tarikh Servis Terakhir" placeholder="e.g. 2025-01-01" />
        <:actions>
          <.button phx-disable-with={@action == :new && "Menyimpan..." || "Mengemaskini..."}>
            <%= if @action == :new do %>
              Simpan Kenderaan
            <% else %>
              Kemas Kini Kenderaan
            <% end %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{vehicle: vehicle} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:vehicle_image_preview_url, vehicle.photo_url)
     |> assign(:remove_vehicle_image, false)
     |> allow_upload(:vehicle_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> assign_new(:form, fn ->
       to_form(Assets.change_vehicle(vehicle))
     end)}
  end

  @impl true
  def handle_event("validate", %{"vehicle" => vehicle_params}, socket) do
    changeset = Assets.change_vehicle(socket.assigns.vehicle, vehicle_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"vehicle" => vehicle_params}, socket) do
    save_vehicle(socket, socket.assigns.action, vehicle_params)
  end

  def handle_event("remove_vehicle_image", _params, socket) do
    socket =
      Enum.reduce(socket.assigns.uploads.vehicle_image.entries, socket, fn entry, acc ->
        Phoenix.LiveView.cancel_upload(acc, :vehicle_image, entry.ref)
      end)

    {:noreply,
     socket
     |> assign(:vehicle_image_preview_url, nil)
     |> assign(:remove_vehicle_image, true)}
  end

  defp save_vehicle(socket, action, vehicle_params) do
    # Handle image uploads
    uploaded_urls =
      consume_uploaded_entries(socket, :vehicle_image, fn %{path: path}, _entry ->
        uploads_dir = Path.expand("./uploads")
        File.mkdir_p!(uploads_dir)
        dest = Path.join(uploads_dir, Path.basename(path))
        File.cp!(path, dest)
        {:ok, "/uploads/#{Path.basename(dest)}"}
      end)

    vehicle_params =
      case {action, uploaded_urls} do
        # If a new image is uploaded
        {_, [url | _]} ->
          Map.put(vehicle_params, "photo_url", url)

        # If editing and user requested image removal
        {:edit, []} when socket.assigns.remove_vehicle_image ->
          Map.put(vehicle_params, "photo_url", nil)

        # Otherwise, just keep params as-is
        _ ->
          vehicle_params
      end

    result =
      case action do
        :edit -> Assets.update_vehicle(socket.assigns.vehicle, vehicle_params)
        :new  -> Assets.create_vehicle(vehicle_params, socket.assigns.current_user_id)
      end

    case result do
      {:ok, vehicle} ->
        notify_parent({:saved, vehicle})

        {:noreply,
         socket
         |> put_flash(:info, flash_message(action))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp flash_message(:edit), do: "Vehicle updated successfully"
  defp flash_message(:new),  do: "Kenderaan berjaya ditambah"

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

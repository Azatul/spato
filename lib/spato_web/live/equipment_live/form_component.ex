defmodule SpatoWeb.EquipmentLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Assets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Gunakan borang ini untuk menguruskan rekod peralatan dalam sistem.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="equipment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

      <div class="space-y-4">
          <div class="text-sm font-medium text-gray-700">Gambar Peralatan</div>
          <div class="relative w-40 h-40 rounded-md bg-gray-200 flex items-center justify-center overflow-hidden">
            <%= if Enum.any?(@uploads.equipment_image.entries) do %>
              <%= for entry <- @uploads.equipment_image.entries do %>
                <.live_img_preview entry={entry} class="object-cover w-full h-full rounded-md" />
              <% end %>
            <% else %>
              <%= if @equipment_image_preview_url do %>
                <img src={@equipment_image_preview_url} class="object-cover w-full h-full rounded-md" />
              <% else %>
                <img src="/images/default-image.jpg" class="object-cover w-full h-full rounded-md" />
              <% end %>
            <% end %>

            <div class="absolute bottom-2 left-1/2 -translate-x-1/2 flex space-x-2">
              <label class="bg-blue-500 text-white rounded-full p-2 cursor-pointer hover:bg-blue-600 transition-colors duration-200">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor"><path d="M13.586 3.586a2 2 0 112.828 2.828l-7.258 7.258a2 2 0 01-.715.42L6 14.12l-.39-.39a2 2 0 01.42-.715l7.258-7.258z" /></svg>
                <.live_file_input upload={@uploads.equipment_image} class="sr-only" />
              </label>
              <button type="button" phx-target={@myself} phx-click="remove_equipment_image" class="bg-red-500 text-white rounded-full p-2 hover:bg-red-600 transition-colors duration-200">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 011 1v6a1 1 0 11-2 0V8a1 1 0 011-1z" clip-rule="evenodd" /></svg>
              </button>
            </div>
          </div>
        </div>

        <.input field={@form[:name]} type="text" label="Nama Peralatan" placeholder="e.g. McBook Pro" />
        <.input
          field={@form[:type]}
          type="select"
          label="Jenis"
          options={[
            {"Laptop / Notebook", "laptop"},
            {"Projektor", "projector"},
            {"Projektor Screen", "projector_screen"},
            {"Printer Mudah Alih", "printer"},
            {"Kamera", "kamera"},
            {"Speaker", "speaker"},
            {"Laser Pointer", "laser_pointer"},
            {"Extension Cord", "extension_cord"},
            {"Whiteboard / Flipchart", "whiteboard"}
          ]}
          prompt="Pilih jenis peralatan"
        />
        <.input field={@form[:serial_number]} type="text" label="No. Siri" placeholder="e.g. 1234567890" />
        <.input field={@form[:total_quantity]} type="number" label="Kuantiti Tersedia" placeholder="e.g. 1" />
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          options={[
            {"Tersedia", "tersedia"},
            {"Tidak Tersedia", "tidak_tersedia"}
          ]}
        />
        <:actions>
          <.button phx-disable-with={@action == :new && "Menyimpan..." || "Mengemaskini..."}>
            <%= if @action == :new do %>
              Simpan Peralatan
            <% else %>
              Kemaskini Peralatan
            <% end %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{equipment: equipment} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:equipment_image_preview_url, equipment.photo_url)
     |> assign(:remove_equipment_image, false)
     |> allow_upload(:equipment_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> assign_new(:form, fn ->
       to_form(Assets.change_equipment(equipment))
     end)}
  end

  @impl true
  def handle_event("validate", %{"equipment" => equipment_params}, socket) do
    changeset = Assets.change_equipment(socket.assigns.equipment, equipment_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"equipment" => equipment_params}, socket) do
    save_equipment(socket, socket.assigns.action, equipment_params)
  end

  def handle_event("remove_equipment_image", _params, socket) do
    socket =
      Enum.reduce(socket.assigns.uploads.equipment_image.entries, socket, fn entry, acc ->
        Phoenix.LiveView.cancel_upload(acc, :equipment_image, entry.ref)
      end)

    {:noreply,
     socket
     |> assign(:equipment_image_preview_url, nil)
     |> assign(:remove_equipment_image, true)}
  end

  defp save_equipment(socket, action, equipment_params) do
    # Handle image uploads
    uploaded_urls =
      consume_uploaded_entries(socket, :equipment_image, fn %{path: path}, _entry ->
        uploads_dir = Path.expand("./uploads")
        File.mkdir_p!(uploads_dir)
        dest = Path.join(uploads_dir, Path.basename(path))
        File.cp!(path, dest)
        {:ok, "/uploads/#{Path.basename(dest)}"}
      end)

    equipment_params =
      case {action, uploaded_urls} do
        # If a new image is uploaded
        {_, [url | _]} ->
          Map.put(equipment_params, "photo_url", url)

        # If editing and user requested image removal
        {:edit, []} when socket.assigns.remove_equipment_image ->
          Map.put(equipment_params, "photo_url", nil)

        # Otherwise, just keep params as-is
        _ ->
          equipment_params
      end

    result =
      case action do
        :edit -> Assets.update_equipment(socket.assigns.equipment, equipment_params)
        :new  -> Assets.create_equipment(equipment_params, socket.assigns.current_user_id)
      end

    case result do
      {:ok, equipment} ->
        notify_parent({:saved, equipment})

        {:noreply,
         socket
         |> put_flash(:info, flash_message(action))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp flash_message(:edit), do: "Peralatan berjaya dikemaskini"
  defp flash_message(:new),  do: "Peralatan berjaya ditambah"

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

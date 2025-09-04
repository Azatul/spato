defmodule SpatoWeb.CateringMenuLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Assets

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Gunakan borang ini untuk menguruskan rekod menu katering.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="catering_menu-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-4">
          <div class="text-sm font-medium text-gray-700">Gambar Menu</div>
          <div class="relative w-40 h-40 rounded-md bg-gray-200 flex items-center justify-center overflow-hidden">
            <%= if Enum.any?(@uploads.menu_image.entries) do %>
              <%= for entry <- @uploads.menu_image.entries do %>
                <.live_img_preview entry={entry} class="object-cover w-full h-full rounded-md" />
              <% end %>
            <% else %>
              <%= if @menu_image_preview_url do %>
                <img src={@menu_image_preview_url} class="object-cover w-full h-full rounded-md" />
              <% else %>
                <img src="/images/default-image.jpg" class="object-cover w-full h-full rounded-md" />
              <% end %>
            <% end %>

            <div class="absolute bottom-2 left-1/2 -translate-x-1/2 flex space-x-2">
              <label class="bg-blue-500 text-white rounded-full p-2 cursor-pointer hover:bg-blue-600 transition-colors duration-200">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor"><path d="M13.586 3.586a2 2 0 112.828 2.828l-7.258 7.258a2 2 0 01-.715.42L6 14.12l-.39-.39a2 2 0 01.42-.715l7.258-7.258z" /></svg>
                <.live_file_input upload={@uploads.menu_image} class="sr-only" />
              </label>
              <button type="button" phx-target={@myself} phx-click="remove_menu_image" class="bg-red-500 text-white rounded-full p-2 hover:bg-red-600 transition-colors duration-200">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 011 1v6a1 1 0 11-2 0V8a1 1 0 011-1z" clip-rule="evenodd" /></svg>
              </button>
            </div>
          </div>
        </div>

        <.input field={@form[:name]} type="text" label="Nama Menu" />
        <.input field={@form[:description]} type="text" label="Keterangan" />
        <.input field={@form[:price_per_head]} type="number" label="Harga/Seorang" step="any" />
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
              Simpan Menu
            <% else %>
              Kemaskini Menu
            <% end %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{catering_menu: catering_menu} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:menu_image_preview_url, catering_menu.photo_url)
     |> assign(:remove_menu_image, false)
     |> allow_upload(:menu_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> assign_new(:form, fn ->
       to_form(Assets.change_catering_menu(catering_menu))
     end)}
  end

  @impl true
  def handle_event("validate", %{"catering_menu" => catering_menu_params}, socket) do
    changeset = Assets.change_catering_menu(socket.assigns.catering_menu, catering_menu_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"catering_menu" => catering_menu_params}, socket) do
    save_catering_menu(socket, socket.assigns.action, catering_menu_params)
  end

  def handle_event("remove_menu_image", _params, socket) do
    socket =
      Enum.reduce(socket.assigns.uploads.menu_image.entries, socket, fn entry, acc ->
        Phoenix.LiveView.cancel_upload(acc, :menu_image, entry.ref)
      end)

    {:noreply,
     socket
     |> assign(:menu_image_preview_url, nil)
     |> assign(:remove_menu_image, true)}
  end

  defp save_catering_menu(socket, action, catering_menu_params) do
    uploaded_urls =
      consume_uploaded_entries(socket, :menu_image, fn %{path: path}, _entry ->
        uploads_dir = Path.expand("./uploads")
        File.mkdir_p!(uploads_dir)
        dest = Path.join(uploads_dir, Path.basename(path))
        File.cp!(path, dest)
        {:ok, "/uploads/#{Path.basename(dest)}"}
      end)

    catering_menu_params =
      case {action, uploaded_urls} do
        {_, [url | _]} ->
          Map.put(catering_menu_params, "photo_url", url)
        {:edit, []} when socket.assigns.remove_menu_image ->
          Map.put(catering_menu_params, "photo_url", nil)
        _ ->
          catering_menu_params
      end

    result =
      case action do
        :edit -> Assets.update_catering_menu(socket.assigns.catering_menu, catering_menu_params)
        :new  -> Assets.create_catering_menu(catering_menu_params, socket.assigns.current_user_id)
      end

    case result do
      {:ok, menu} ->
        notify_parent({:saved, menu})

        {:noreply,
         socket
         |> put_flash(:info, flash_message(action))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp flash_message(:edit), do: "Menu berjaya dikemaskini"
  defp flash_message(:new),  do: "Menu berjaya ditambah"

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

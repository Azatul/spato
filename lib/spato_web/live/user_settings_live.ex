defmodule SpatoWeb.UserSettingsLive do
  use SpatoWeb, :live_view

  alias Spato.Accounts
  alias SpatoWeb.Components.Headbar

  def render(assigns) do
    ~H"""
    <Headbar.headbar current_user={@current_user} title="Tetapan" full_width={true} />
    <div class="container mx-auto max-w-5xl pt-20">
      <div class="bg-white rounded-lg shadow-lg p-6 md:p-8 space-y-8">
        <div class="flex items-center justify-between mb-6">
          <h1 class="text-3xl font-semibold text-gray-800">Tetapan</h1>
          <.link navigate={@dashboard_path} class="flex items-center text-blue-600 hover:text-blue-800 transition-colors duration-200">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M9.707 16.707a1 1 0 01-1.414 0l-6-6a1 1 0 010-1.414l6-6a1 1 0 011.414 1.414L5.414 9H17a1 1 0 110 2H5.414l4.293 4.293a1 1 0 010 1.414z" clip-rule="evenodd" /></svg>
            Kembali ke dashboard
          </.link>
        </div>

        <div>
          <h2 class="text-xl font-semibold text-gray-700 mb-6 border-b pb-2">Maklumat Pengguna</h2>
          <.simple_form
            for={@profile_form}
            id="profile_form"
            phx-change="validate_profile"
            phx-submit="save_profile"
          >
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <div class="space-y-6">
                <.input field={@profile_form[:full_name]} type="text" label="Nama Penuh" required />
                <.input field={@profile_form[:ic_number]} type="text" label="Nombor Kad Pengenalan" required />
                <.input field={@profile_form[:dob]} type="date" label="Tarikh Lahir" required />
                <.input field={@profile_form[:phone_number]} type="text" label="No. Telefon" />
                <.input field={@profile_form[:address]} type="textarea" label="Alamat" rows="2" />
              </div>

              <div class="space-y-6">
                <.input field={@profile_form[:department_id]} type="select" label="Nama Jabatan" options={@department_options} />
                <.input field={@profile_form[:position]} type="text" label="Jawatan" required />
                <.input field={@profile_form[:gender]} type="select" label="Jantina" options={@gender_options} required />
                <.input field={@profile_form[:employment_status]} type="select" label="Status Pekerjaan" options={@employment_status_options} required />
                <.input field={@profile_form[:date_joined]} type="date" label="Tarikh Lantikan" required />
              </div>

              <div class="hidden lg:flex flex-col items-center space-y-4">
                <div class="text-center mb-2">
                  <h3 class="text-sm font-medium text-gray-700">Foto Profil</h3>
                </div>
                <div class="relative w-40 h-40 rounded-full bg-gray-200 flex items-center justify-center overflow-hidden">
                  <%= if Enum.any?(@uploads.profile_image.entries) do %>
                    <%= for entry <- @uploads.profile_image.entries do %>
                      <.live_img_preview entry={entry} class="object-cover w-full h-full rounded-full" />
                    <% end %>
                  <% else %>
                    <%= if @profile_image_preview_url do %>
                      <img src={@profile_image_preview_url} class="object-cover w-full h-full rounded-full" />
                    <% else %>
                      <img src="/images/default-image.jpg" class="object-cover w-full h-full rounded-full" />
                    <% end %>
                  <% end %>

                  <div class="absolute bottom-2 left-1/2 -translate-x-1/2 flex space-x-2">
                    <label class="bg-blue-500 text-white rounded-full p-2 cursor-pointer hover:bg-blue-600 transition-colors duration-200">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor"><path d="M13.586 3.586a2 2 0 112.828 2.828l-7.258 7.258a2 2 0 01-.715.42L6 14.12l-.39-.39a2 2 0 01.42-.715l7.258-7.258z" /></svg>
                      <.live_file_input upload={@uploads.profile_image} class="sr-only" />
                    </label>
                    <button type="button" phx-click="remove_profile_image" class="bg-red-500 text-white rounded-full p-2 hover:bg-red-600 transition-colors duration-200">
                      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 20 20" fill="currentColor"><path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 011 1v6a1 1 0 11-2 0V8a1 1 0 011-1z" clip-rule="evenodd" /></svg>
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <:actions>
              <div class="flex justify-end gap-4 mt-6">
                <.button class="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-100" phx-disable-with="Menyimpan...">Simpan</.button>
                <.button type="button" phx-click="cancel_profile" class="px-6 py-2 bg-red-500 text-white rounded-md hover:bg-red-600">Batal</.button>
              </div>
            </:actions>
          </.simple_form>
        </div>

        <hr class="border-gray-300" />

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="bg-gray-50 rounded-lg shadow-sm p-6 border border-gray-200">
            <h3 class="text-lg font-semibold text-gray-700 mb-4">Kemaskini Emel</h3>
            <.simple_form
              for={@email_form}
              id="email_form"
              phx-submit="update_email"
              phx-change="validate_email"
            >
              <.input field={@email_form[:email]} type="email" label="Emel Pengguna" required />
              <.input
                field={@email_form[:current_password]}
                name="current_password"
                id="current_password_for_email"
                type="password"
                label="Taip Kata Laluan"
                value={@email_form_current_password}
                required
              />
              <:actions>
                <div class="flex justify-end gap-4 mt-6">
                  <.button class="px-6 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600" phx-disable-with="Mengemas kini...">Kemaskini</.button>
                  <.button type="button" class="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-100" phx-click="cancel_email">Batal</.button>
                </div>
              </:actions>
            </.simple_form>
          </div>

          <div class="bg-gray-50 rounded-lg shadow-sm p-6 border border-gray-200">
            <h3 class="text-lg font-semibold text-gray-700 mb-4">Kemaskini Kata Laluan</h3>
            <.simple_form
              for={@password_form}
              id="password_form"
              action={~p"/users/log_in?_action=password_updated"}
              method="post"
              phx-change="validate_password"
              phx-submit="update_password"
              phx-trigger-action={@trigger_submit}
            >
              <input
                name={@password_form[:email].name}
                type="hidden"
                id="hidden_user_email"
                value={@current_email}
              />
              <.input field={@password_form[:password]} type="password" label="Kata Laluan Baru" required />
              <.input
                field={@password_form[:password_confirmation]}
                type="password"
                label="Taip Semula Kata Laluan Baru"
              />
              <.input
                field={@password_form[:current_password]}
                name="current_password"
                type="password"
                label="Kata Laluan Semasa"
                id="current_password_for_password"
                value={@current_password}
                required
              />
              <:actions>
                <div class="flex justify-end gap-4 mt-6">
                  <.button class="px-6 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600" phx-disable-with="Mengemas kini...">Kemaskini</.button>
                  <.button type="button" class="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-100" phx-click="cancel_password">Batal</.button>
                </div>
              </:actions>
            </.simple_form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    profile_struct = Accounts.get_or_init_user_profile_for_user(user)
    profile_changeset = Accounts.change_user_profile(profile_struct)

    departments = Accounts.list_departments()
    department_options = Enum.map(departments, &{&1.name, &1.id})

    employment_status_options = [
      {"Sepenuh Masa", "full_time"},
      {"Separuh Masa", "part_time"},
      {"Kontrak", "contract"},
      {"Praktikal", "intern"}
    ]

    gender_options = [
      {"Lelaki", "male"},
      {"Perempuan", "female"}
    ]

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:profile_form, to_form(profile_changeset, as: "profile"))
      |> assign(:department_options, department_options)
      |> assign(:employment_status_options, employment_status_options)
      |> assign(:gender_options, gender_options)
      |> assign(:profile_image_preview_url, profile_struct.profile_picture_url)
      |> assign(:remove_profile_image, false)
      |> allow_upload(:profile_image, accept: ~w(.jpg .jpeg .png), max_entries: 1)
      |> assign(:dashboard_path, if(user.role == "admin", do: ~p"/admin/dashboard", else: ~p"/dashboard"))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_user_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/users/settings/confirm_email/#{&1}")
        )

        info = "A link to confirm your email change has been sent to the new address."
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end

  def handle_event("validate_profile", %{"profile" => profile_params}, socket) do
    profile_struct = Accounts.get_or_init_user_profile_for_user(socket.assigns.current_user)

    profile_form =
      profile_struct
      |> Accounts.change_user_profile(profile_params)
      |> Map.put(:action, :validate)
      |> to_form(as: "profile")

    {:noreply, assign(socket, profile_form: profile_form)}
  end

  def handle_event("save_profile", %{"profile" => profile_params}, socket) do
    user = socket.assigns.current_user

    # Save uploaded image (if present) and inject URL into params
    uploaded_urls =
      consume_uploaded_entries(socket, :profile_image, fn %{path: path}, _entry ->
        uploads_dir = Path.join(["priv", "static", "uploads"]) |> Path.expand()
        File.mkdir_p!(uploads_dir)
        dest = Path.join(uploads_dir, Path.basename(path))
        File.cp!(path, dest)
        {:ok, "/uploads/#{Path.basename(dest)}"}
      end)

    profile_params =
      case uploaded_urls do
        [url | _] -> Map.put(profile_params, "profile_picture_url", url)
        _ ->
          if socket.assigns.remove_profile_image do
            Map.put(profile_params, "profile_picture_url", nil)
          else
            profile_params
          end
      end

    case Accounts.upsert_user_profile_for_user(user, profile_params) do
      {:ok, profile} ->
        {:noreply,
          socket
          |> put_flash(:info, "Profil berjaya dikemas kini.")
          |> assign(:profile_form, to_form(Accounts.change_user_profile(profile), as: "profile"))
          |> assign(:profile_image_preview_url, profile.profile_picture_url)
          |> assign(:remove_profile_image, false)}

      {:error, changeset} ->
        {:noreply, assign(socket, profile_form: to_form(Map.put(changeset, :action, :insert), as: "profile"))}
    end
  end

  def handle_event("cancel_profile", _params, socket) do
    user = socket.assigns.current_user
    profile = Accounts.get_or_init_user_profile_for_user(user)
    {:noreply,
      socket
      |> assign(:profile_form, to_form(Accounts.change_user_profile(profile), as: "profile"))
      |> assign(:profile_image_preview_url, profile.profile_picture_url)
      |> assign(:remove_profile_image, false)}
  end

  def handle_event("remove_profile_image", _params, socket) do
    # Cancel any in-flight uploads and clear preview; persist on save
    socket =
      Enum.reduce(socket.assigns.uploads.profile_image.entries, socket, fn entry, acc ->
        Phoenix.LiveView.cancel_upload(acc, :profile_image, entry.ref)
      end)

    {:noreply,
      socket
      |> assign(:profile_image_preview_url, nil)
      |> assign(:remove_profile_image, true)}
  end

  def handle_event("cancel_email", _params, socket) do
    user = socket.assigns.current_user
    {:noreply,
      socket
      |> assign(:email_form, to_form(Accounts.change_user_email(user)))
      |> assign(:email_form_current_password, nil)}
  end

  def handle_event("cancel_password", _params, socket) do
    user = socket.assigns.current_user
    {:noreply,
      socket
      |> assign(:password_form, to_form(Accounts.change_user_password(user)))
      |> assign(:current_password, nil)}
  end
end

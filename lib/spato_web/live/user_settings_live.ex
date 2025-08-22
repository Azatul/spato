defmodule SpatoWeb.UserSettingsLive do
  use SpatoWeb, :live_view

  alias Spato.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Tetapan
      <:subtitle>Urus profil, alamat emel dan kata laluan anda</:subtitle>
    </.header>

    <div class="flex justify-end mb-4">
      <.link navigate={@dashboard_path} class="inline-flex items-center gap-2 rounded-md bg-blue-600 px-3 py-2 text-white hover:bg-blue-700">
        ← Kembali ke dashboard
      </.link>
    </div>

    <div class="space-y-12 divide-y">
      <div>
        <div class="rounded-lg border border-gray-200 bg-gray-50 p-6">
          <h3 class="text-base font-semibold mb-4">Maklumat Pengguna</h3>
          <.simple_form
            for={@profile_form}
            id="profile_form"
            phx-change="validate_profile"
            phx-submit="save_profile"
          >
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="space-y-4 md:col-span-2">
                <.input field={@profile_form[:full_name]} type="text" label="Nama Penuh" required />
                <.input field={@profile_form[:department_id]} type="select" label="Nama Jabatan" options={@department_options} />
                <.input field={@profile_form[:ic_number]} type="text" label="Nombor Kad Pengenalan" required />
                <.input field={@profile_form[:position]} type="text" label="Jawatan" required />
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <.input field={@profile_form[:dob]} type="date" label="Tarikh Lahir" required />
                  <.input field={@profile_form[:gender]} type="select" label="Jantina" options={@gender_options} required />
                  <.input field={@profile_form[:date_joined]} type="date" label="Tarikh Lantikan" required />
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <.input field={@profile_form[:phone_number]} type="text" label="No. Telefon" />
                  <.input field={@profile_form[:employment_status]} type="select" label="Status Pekerjaan" options={@employment_status_options} required />
                </div>
                <.input field={@profile_form[:address]} type="text" label="Alamat" />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-2">Foto Profil</label>
                <div class="rounded-lg border bg-white p-4 flex flex-col items-center">
                  <div class="w-40 h-40 rounded-full overflow-hidden bg-gray-100 flex items-center justify-center mb-3">
                    <%= if Enum.any?(@uploads.profile_image.entries) do %>
                      <%= for entry <- @uploads.profile_image.entries do %>
                        <.live_img_preview entry={entry} class="object-cover w-full h-full" />
                      <% end %>
                    <% else %>
                      <%= if @profile_image_preview_url do %>
                        <img src={@profile_image_preview_url} class="object-cover w-full h-full" />
                      <% else %>
                        <div class="text-xs text-gray-400">Tiada gambar</div>
                      <% end %>
                    <% end %>
                  </div>
                  <.live_file_input upload={@uploads.profile_image} class="mb-2" />
                  <div class="flex gap-2">
                    <.button type="button" phx-click="remove_profile_image" class="bg-gray-200 text-gray-900 hover:bg-gray-300">Buang</.button>
                  </div>
                </div>
              </div>
            </div>
            <:actions>
              <div class="flex gap-3">
                <.button phx-disable-with="Menyimpan...">Simpan</.button>
                <.button type="button" phx-click="cancel_profile" class="bg-gray-200 text-gray-900 hover:bg-gray-300">Batal</.button>
              </div>
            </:actions>
          </.simple_form>
        </div>
      </div>
      <div>
        <div class="rounded-lg border border-gray-200 bg-gray-50 p-6">
          <h3 class="text-base font-semibold mb-4">Maklumat Log Masuk</h3>
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
              label="Kata Laluan Semasa"
              value={@email_form_current_password}
              required
            />
            <:actions>
              <div class="flex gap-3">
                <.button phx-disable-with="Mengemas kini...">Kemaskini</.button>
                <.button type="button" class="bg-gray-200 text-gray-900 hover:bg-gray-300" phx-click="cancel_email">Batal</.button>
              </div>
            </:actions>
          </.simple_form>
        </div>
      </div>
      <div>
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
          <.input field={@password_form[:password]} type="password" label="Kata Laluan" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Taip Semula Kata Laluan"
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
            <div class="flex gap-3">
              <.button phx-disable-with="Mengemas kini...">Kemaskini</.button>
              <.button type="button" class="bg-gray-200 text-gray-900 hover:bg-gray-300" phx-click="cancel_password">Batal</.button>
            </div>
          </:actions>
        </.simple_form>
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
        _ -> profile_params
      end

    case Accounts.upsert_user_profile_for_user(user, profile_params) do
      {:ok, profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profil berjaya dikemas kini.")
         |> assign(:profile_form, to_form(Accounts.change_user_profile(profile), as: "profile"))
         |> assign(:profile_image_preview_url, profile.profile_picture_url)}

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
     |> assign(:profile_image_preview_url, profile.profile_picture_url)}
  end

  def handle_event("remove_profile_image", _params, socket) do
    # Only affects preview; user must save to persist removal
    {:noreply, assign(socket, :profile_image_preview_url, nil)}
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

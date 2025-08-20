defmodule SpatoWeb.UserProfileLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Accounts

  @impl true
  def update(assigns, socket) do
    departments = Accounts.list_departments()
    changeset = Accounts.change_user_profile(assigns.user_profile)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:departments, departments)
     |> assign(:gender_options, [{"Lelaki", "male"}, {"Perempuan", "female"}])
     |> assign(:employment_status_options, [
       {"Sepenuh Masa", "full_time"},
       {"Separuh Masa", "part_time"},
       {"Kontrak", "contract"},
       {"Pelatih", "intern"}
     ])
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>{@title}<:subtitle>Pengurusan profil pengguna.</:subtitle></.header>

      <.simple_form
        for={@form}
        id="user_profile-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:full_name]} type="text" label="Nama Penuh" />
        <.input field={@form[:dob]} type="date" label="Tarikh Lahir" />
        <.input field={@form[:ic_number]} type="text" label="No. Kad Pengenalan" />
        <.input field={@form[:gender]} type="select" label="Jantina" options={@gender_options} />
        <.input field={@form[:phone_number]} type="text" label="No.Telefon" />
        <.input field={@form[:address]} type="text" label="Alamat" />
        <.input field={@form[:position]} type="text" label="Jawatan" />
        <.input field={@form[:employment_status]} type="select" label="Status Pekerjaan" options={@employment_status_options} />
        <.input field={@form[:date_joined]} type="date" label="Tarikh Lantikan" />

        <!-- Automatically set user_id -->
        <input type="hidden" name="user_profile[user_id]" value={@current_user.id} />

        <!-- Department -->
        <.input
          field={@form[:department_id]}
          type="select"
          label="Jabatan"
          options={for d <- @departments, do: {d.name, d.id}}
        />

        <:actions>
          <.button phx-disable-with="Saving...">Simpan</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"user_profile" => params}, socket) do
    changeset =
      socket.assigns.user_profile
      |> Accounts.change_user_profile(params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"user_profile" => params}, socket) do
    save_user_profile(socket, socket.assigns.action, params)
  end

  defp save_user_profile(socket, :edit, params) do
    case Accounts.update_user_profile(socket.assigns.user_profile, params) do
      {:ok, user_profile} ->
        notify_parent({:saved, user_profile})

        {:noreply,
         socket
         |> put_flash(:info, "Profil pengguna berjaya dikemaskini.")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp save_user_profile(socket, :new, params) do
    case Accounts.create_user_profile(params) do
      {:ok, user_profile} ->
        notify_parent({:saved, user_profile})

        {:noreply,
         socket
         |> put_flash(:info, "Profil pengguna berjaya dicipta.")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

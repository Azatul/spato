defmodule SpatoWeb.UserProfileLive.FormComponent do
  use SpatoWeb, :live_component

  alias Spato.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage user_profile records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="user_profile-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:full_name]} type="text" label="Full name" />
        <.input field={@form[:dob]} type="date" label="Dob" />
        <.input field={@form[:ic_number]} type="text" label="Ic number" />
        <.input field={@form[:gender]} type="text" label="Gender" />
        <.input field={@form[:phone_number]} type="text" label="Phone number" />
        <.input field={@form[:address]} type="text" label="Address" />
        <.input field={@form[:position]} type="text" label="Position" />
        <.input field={@form[:employment_status]} type="text" label="Employment status" />
        <.input field={@form[:date_joined]} type="date" label="Date joined" />
        <.input field={@form[:profile_picture_url]} type="text" label="Profile picture url" />
        <.input field={@form[:last_login_at]} type="datetime-local" label="Last login at" />
        <.input field={@form[:is_active]} type="checkbox" label="Is active" />
        <:actions>
          <.button phx-disable-with="Saving...">Save User profile</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user_profile: user_profile} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Accounts.change_user_profile(user_profile))
     end)}
  end

  @impl true
  def handle_event("validate", %{"user_profile" => user_profile_params}, socket) do
    changeset = Accounts.change_user_profile(socket.assigns.user_profile, user_profile_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user_profile" => user_profile_params}, socket) do
    save_user_profile(socket, socket.assigns.action, user_profile_params)
  end

  defp save_user_profile(socket, :edit, user_profile_params) do
    case Accounts.update_user_profile(socket.assigns.user_profile, user_profile_params) do
      {:ok, user_profile} ->
        notify_parent({:saved, user_profile})

        {:noreply,
         socket
         |> put_flash(:info, "User profile updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user_profile(socket, :new, user_profile_params) do
    case Accounts.create_user_profile(user_profile_params) do
      {:ok, user_profile} ->
        notify_parent({:saved, user_profile})

        {:noreply,
         socket
         |> put_flash(:info, "User profile created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

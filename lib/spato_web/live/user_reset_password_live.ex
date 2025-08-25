defmodule SpatoWeb.UserResetPasswordLive do
  use SpatoWeb, :live_view

  alias Spato.Accounts

  def render(assigns) do
    ~H"""
    <div class="bg-[#bcd2e4] min-h-screen w-full flex items-center justify-center">
      <div class="bg-white rounded-lg shadow-md p-8 w-full max-w-sm">

        <!-- Logo + Title -->
        <div class="flex flex-col items-center justify-center mb-6 text-center">
          <img src={~p"/images/spato.png"} alt="Logo SPATO" class="w-72 mb-4">
          <.header class="text-xl font-semibold text-center">Tetapkan Semula Kata Laluan</.header>
        </div>

        <!-- Reset Password Form -->
        <.simple_form
          for={@form}
          id="reset_password_form"
          phx-submit="reset_password"
          phx-change="validate"
        >
          <.error :if={@form.errors != []}>
            Maaf, terdapat ralat! Sila semak medan di bawah.
          </.error>

          <!-- Kata Laluan Baru -->
          <div class="mb-4">
            <.input
              field={@form[:password]}
              type="password"
              label="Kata Laluan Baru"
              placeholder="Masukkan kata laluan baru"
              class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#224179]"
              required
            />
          </div>

          <!-- Sahkan Kata Laluan -->
          <div class="mb-4">
            <.input
              field={@form[:password_confirmation]}
              type="password"
              label="Sahkan Kata Laluan"
              placeholder="Sahkan kata laluan baru"
              class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#224179]"
              required
            />
          </div>

          <!-- Actions: Reset Button -->
          <:actions>
            <.button
              phx-disable-with="Sedang menetapkan..."
              class="block w-full py-2 rounded-md text-white hover:bg-[#20386b] transition font-semibold bg-[#224179]"
            >
              Tetapkan Semula Kata Laluan
            </.button>
          </:actions>
        </.simple_form>

        <!-- Footer Links -->
        <p class="text-center text-sm mt-4">
          <.link href={~p"/users/register"} class="text-[#224179] hover:underline">Daftar Akaun</.link>
          | <.link href={~p"/users/log_in"} class="text-[#224179] hover:underline">Log Masuk</.link>
        </p>

      </div>
    </div>
    """
    end

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} ->
          Accounts.change_user_password(user)

        _ ->
          %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Password reset successfully.")
         |> redirect(to: ~p"/users/log_in")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "user"))
  end
end

defmodule SpatoWeb.UserForgotPasswordLive do
  use SpatoWeb, :live_view

  alias Spato.Accounts

  def render(assigns) do
    ~H"""
    <div class="bg-[#bcd2e4] min-h-screen w-full flex items-center justify-center">
      <div class="bg-white rounded-lg shadow-md p-8 w-full max-w-sm">

        <!-- Logo + Title -->
        <div class="flex flex-col items-center justify-center mb-6 text-center">
          <img src={~p"/images/spato.png"} alt="Logo SPATO" class="w-72 mb-4">
          <.header class="text-xl font-semibold text-center">
            Lupa Kata Laluan?
            <:subtitle>Kami akan menghantar pautan tetapan semula kata laluan ke emel anda</:subtitle>
          </.header>
        </div>

        <!-- Reset Password Email Form -->
        <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
          <.input
            field={@form[:email]}
            type="email"
            placeholder="Masukkan emel"
            class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#224179]"
            required
          />
          <:actions>
            <.button
              phx-disable-with="Sedang menghantar..."
              class="block w-full py-2 rounded-md text-white hover:bg-[#20386b] transition font-semibold bg-[#224179]"
            >
              Hantar Arahan Tetapan Semula Kata Laluan
            </.button>
          </:actions>
        </.simple_form>

      </div>
    </div>
    """
    end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end

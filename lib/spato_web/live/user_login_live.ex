defmodule SpatoWeb.UserLoginLive do
  use SpatoWeb, :live_view

  def render(assigns) do
    ~H"""
      <div class="bg-gradient-to-br from-[#cde2f3] to-[#a1c4e8] min-h-screen w-full flex items-center justify-center font-inter">
      <div class="bg-white rounded-2xl shadow-xl p-10 w-full max-w-md">

        <!-- Logo + Title -->
        <div class="flex flex-col items-center justify-center mb-8 text-center">
          <img src={~p"/images/spato.png"} alt="SPATO Logo" class="w-64 mb-4">
        </div>

        <!-- Login Form -->
        <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">

          <!-- Email field -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-700 mb-2">Emel</label>
            <.input
              field={@form[:email]}
              type="email"
              placeholder="Masukkan emel"
              class="w-full border border-gray-300 rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#224179] focus:border-[#224179] transition"
              required
            />
          </div>

          <!-- Password field -->
          <div class="mb-6">
            <label class="block text-sm font-medium text-gray-700 mb-2">Kata Laluan</label>
            <.input
              field={@form[:password]}
              type="password"
              placeholder="Masukkan kata laluan"
              class="w-full border border-gray-300 rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#224179] focus:border-[#224179] transition"
              required
            />
            <div class="text-right mt-2">
              <.link href={~p"/users/reset_password"} class="text-sm text-[#224179] hover:underline">
                Lupa kata laluan?
              </.link>
            </div>
          </div>

          <!-- Actions: Log in button -->
          <:actions>
            <.button phx-disable-with="Logging in..." class="block w-full py-3 rounded-lg text-white font-semibold bg-gradient-to-r from-[#224179] to-[#1b2f5a] hover:from-[#1b2f5a] hover:to-[#16306a] transition">
              Log Masuk
            </.button>
          </:actions>

        </.simple_form>

      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end

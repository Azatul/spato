defmodule SpatoWeb.UserLoginLive do
  use SpatoWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="bg-[#bcd2e4] min-h-screen w-full flex items-center justify-center">
      <div class="bg-white rounded-lg shadow-md p-8 w-full max-w-sm">

        <!-- Logo + Title -->
        <div class="flex items-center justify-center mb-6 text-center">
          <img src={~p"/images/spato.png"} alt="SPATO Logo" class="w-72">
        </div>

        <!-- Login Form -->

       <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">

          <!-- Email field -->
          <div>
            <label class="block text-sm font-medium text-gray-800 mb-1">Emel</label>
            <.input
              field={@form[:email]}
              type="email"
              placeholder="Masukkan emel"
              class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#224179]"
              required
            />
          </div>

          <!-- Password field -->
          <div>
            <label class="block text-sm font-medium text-gray-800 mb-1">Kata Laluan</label>
            <.input
              field={@form[:password]}
              type="password"
              placeholder="Masukkan kata laluan"
              class="w-full border border-gray-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-[#224179]"
              required
            />
            <div class="text-right mt-1">
              <.link href={~p"/users/reset_password"} class="text-sm text-[#224179] hover:underline">
                Lupa kata laluan?
              </.link>
            </div>
          </div>

          <!-- Actions: Log in button -->
          <:actions>
            <.button phx-disable-with="Logging in..." class="block w-full py-2 rounded-md text-white bg-[#224179] hover:bg-[#20386b] transition font-semibold">
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

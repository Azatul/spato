defmodule SpatoWeb.CateringMenuLive.Show do
  use SpatoWeb, :live_view

  alias Spato.Assets

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:catering_menu, Assets.get_catering_menu!(id))}
  end

  defp page_title(:show), do: "Show Catering menu"
  defp page_title(:edit), do: "Edit Catering menu"
end

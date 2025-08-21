defmodule SpatoWeb.CateringMenuLive.Index do
  use SpatoWeb, :live_view

  alias Spato.Assets
  alias Spato.Assets.CateringMenu

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :catering_menus, Assets.list_catering_menus())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Catering menu")
    |> assign(:catering_menu, Assets.get_catering_menu!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Catering menu")
    |> assign(:catering_menu, %CateringMenu{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Catering menus")
    |> assign(:catering_menu, nil)
  end

  @impl true
  def handle_info({SpatoWeb.CateringMenuLive.FormComponent, {:saved, catering_menu}}, socket) do
    {:noreply, stream_insert(socket, :catering_menus, catering_menu)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    catering_menu = Assets.get_catering_menu!(id)
    {:ok, _} = Assets.delete_catering_menu(catering_menu)

    {:noreply, stream_delete(socket, :catering_menus, catering_menu)}
  end
end

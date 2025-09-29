defmodule SpatoWeb.NotificationMixin do
  @moduledoc """
  Mixin module untuk menambah fungsi notifikasi ke LiveView pages.
  """

  alias Spato.Notifications

  defmacro __using__(_opts) do
    quote do
      import SpatoWeb.NotificationMixin
    end
  end

  @doc """
  Load notifications untuk user/admin dan assign ke socket.
  """
  def load_notifications(socket) do
    user = socket.assigns.current_user
    role = if user.role == "admin", do: :admin, else: :user

    notifications = case role do
      :user -> Notifications.list_user_notifications(user.id)
      :admin -> Notifications.list_admin_notifications(user.id)
    end

    unread_count = Notifications.count_unread(user.id, role)

    socket
    |> Phoenix.Component.assign(:notifications, notifications)
    |> Phoenix.Component.assign(:unread_count, unread_count)
  end

  @doc """
  Handle event untuk toggle notifications.
  """
  def handle_toggle_notifications(_params, socket) do
    {:noreply, Phoenix.Component.assign(socket, :show_notifications, !socket.assigns.show_notifications)}
  end

  @doc """
  Handle event untuk mark notification sebagai read.
  """
  def handle_read_notification(%{"id" => id}, socket) do
    case Notifications.get_notification(id) do
      %{status: "unread"} = notification ->
        {:ok, _} = Notifications.mark_as_read(notification)
        socket = load_notifications(socket)
        {:noreply, socket}
      _ ->
        {:noreply, socket}
    end
  end

  @doc """
  Default notification assigns untuk mount function.
  """
  def default_notification_assigns do
    [
      show_notifications: false
    ]
  end
end

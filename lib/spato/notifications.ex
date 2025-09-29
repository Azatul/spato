defmodule Spato.Notifications do
  @moduledoc """
  Context untuk urus notifikasi (user & admin).
  """

  import Ecto.Query, warn: false
  alias Spato.Repo
  alias Spato.Notifications.Notification

  # Buat notification baru
  def create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  # Get notification by ID
  def get_notification(id) do
    Repo.get(Notification, id)
  end

  # Senarai notification utk user
  def list_user_notifications(user_id) do
    Notification
    |> where([n], n.user_id == ^user_id)
    |> order_by([n], desc: n.inserted_at)
    |> limit(10)
    |> Repo.all()
  end

  # Senarai notification utk admin
  def list_admin_notifications(admin_id) do
    Notification
    |> where([n], n.admin_id == ^admin_id)
    |> order_by([n], desc: n.inserted_at)
    |> limit(10)
    |> Repo.all()
  end

  # Kira jumlah notification belum dibaca
  def count_unread(user_or_admin_id, role \\ :user) do
    query =
      case role do
        :user ->
          from n in Notification,
            where: n.user_id == ^user_or_admin_id and n.status == "unread"

        :admin ->
          from n in Notification,
            where: n.admin_id == ^user_or_admin_id and n.status == "unread"
      end

    Repo.aggregate(query, :count, :id)
  end

  # Tandakan notifikasi sebagai read
  def mark_as_read(%Notification{} = notif) do
    notif
    |> Ecto.Changeset.change(status: "read")
    |> Repo.update()
  end
end

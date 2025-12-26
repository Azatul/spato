defmodule Spato.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notifications" do
    field :title, :string
    field :message, :string
    field :type, :string
    field :status, :string, default: "unread"

    belongs_to :user, Spato.Accounts.User
    belongs_to :admin, Spato.Accounts.User

    timestamps()
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:title, :message, :type, :status, :user_id, :admin_id])
    |> validate_required([:title, :message, :type])
    |> validate_inclusion(:type, ["booking_created", "booking_approved", "booking_rejected"])
    |> validate_inclusion(:status, ["unread", "read"])
  end
end

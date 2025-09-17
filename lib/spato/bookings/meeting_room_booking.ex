defmodule Spato.Bookings.MeetingRoomBooking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meeting_room_bookings" do
    field :status, :string, default: "pending"
    field :purpose, :string
    field :participants, :integer
    field :start_time, :naive_datetime
    field :end_time, :naive_datetime
    field :is_recurring, :boolean, default: false
    field :recurrence_pattern, :string
    field :notes, :string

    # Relationships
    belongs_to :user, Spato.Accounts.User
    belongs_to :room, Spato.Assets.MeetingRoom, foreign_key: :meeting_room_id
    belongs_to :approved_by_user, Spato.Accounts.User
    belongs_to :cancelled_by_user, Spato.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meeting_room_booking, attrs) do
    meeting_room_booking
    |> cast(attrs, [
      :purpose,
      :participants,
      :start_time,
      :end_time,
      :is_recurring,
      :recurrence_pattern,
      :notes,
      :user_id,
      :meeting_room_id,
      :approved_by_user_id,
      :cancelled_by_user_id
    ])
    |> validate_required([
      :purpose,
      :participants,
      :start_time,
      :end_time
    ])
    |> put_change(:status, meeting_room_booking.status || "pending")
  end
end

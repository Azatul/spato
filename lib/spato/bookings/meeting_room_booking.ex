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
    field :user_id, :id
    field :room_id, :id
    field :approved_by_user_id, :id
    field :cancelled_by_user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meeting_room_booking, attrs) do
    meeting_room_booking
    |> cast(attrs, [:purpose, :participants, :start_time, :end_time, :is_recurring, :recurrence_pattern, :notes])
    |> validate_required([:purpose, :participants, :start_time, :end_time, :is_recurring, :recurrence_pattern, :notes])
    |> put_change(:status, meeting_room_booking.status || "pending")
  end
end

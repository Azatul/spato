defmodule Spato.Bookings.MeetingRoomBooking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meeting_room_bookings" do
    field :status, :string, default: "pending"
    field :purpose, :string
    field :participants, :integer
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :notes, :string
    field :rejection_reason, :string

    belongs_to :user, Spato.Accounts.User
    belongs_to :meeting_room, Spato.Assets.MeetingRoom
    belongs_to :approved_by_user, Spato.Accounts.User
    belongs_to :cancelled_by_user, Spato.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meeting_room_booking, attrs) do
    meeting_room_booking
    |> cast(attrs, [:participants, :user_id, :meeting_room_id, :approved_by_user_id, :cancelled_by_user_id, :purpose, :start_time, :end_time, :status, :notes, :rejection_reason])
    |> validate_required([:purpose, :participants, :start_time, :end_time])
    |> validate_inclusion(:status, ["pending", "approved", "rejected", "cancelled", "completed"])
    |> unique_constraint(:meeting_room_id, name: :no_overlapping_meeting_room_bookings)
    |> update_change(:status, &String.downcase/1)
    |> Spato.Bookings.validate_datetime_order(:start_time, :end_time)
  end

  def human_status("pending"), do: "Menunggu Kelulusan"
  def human_status("approved"), do: "Diluluskan"
  def human_status("rejected"), do: "Ditolak"
  def human_status("cancelled"), do: "Dibatalkan"
  def human_status("completed"), do: "Selesai"
  def human_status(other), do: other
end

defmodule Spato.Assets.MeetingRoom do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meeting_rooms" do
    field :name, :string
    field :status, :string
    field :location, :string
    field :capacity, :integer
    field :available_facility, :string
    field :photo_url, :string

    belongs_to :user, Spato.Accounts.User
    belongs_to :created_by, Spato.Accounts.User
    has_many :meeting_room_bookings, Spato.Bookings.MeetingRoomBooking, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meeting_room, attrs) do
    meeting_room
    |> cast(attrs, [:user_id, :created_by_id, :name, :location, :capacity, :available_facility, :photo_url, :status])
    |> validate_required([:created_by_id, :name, :location, :capacity, :available_facility, :status])
    |> validate_inclusion(:status, ["tersedia", "tidak_tersedia"])
    |> unique_constraint(:name, message: "Nama ruang meeting sudah digunakan")
    |> unique_constraint(:name, name: :meeting_rooms_name_lower_index, message: "Nama ruang meeting sudah digunakan")
  end

  # Map DB values to human-readable labels
  def human_status("tersedia"), do: "Tersedia"
  def human_status("tidak_tersedia"), do: "Tidak Tersedia"

  # Catch-all clause for any other value
  def human_status(other), do: other
end

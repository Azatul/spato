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
    field :created_by_user_id, :id
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meeting_room, attrs) do
    meeting_room
    |> cast(attrs, [:name, :location, :capacity, :available_facility, :photo_url, :status])
    |> validate_required([:name, :location, :capacity, :available_facility, :photo_url, :status])
  end
end

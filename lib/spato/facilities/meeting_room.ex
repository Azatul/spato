defmodule Spato.Facilities.MeetingRoom do
  use Ecto.Schema
  import Ecto.Changeset

  schema "meeting_rooms" do
    field :name, :string
    field :status, :string
    field :location, :string
    field :features, :string
    field :capacity, :integer
    field :availability, :string
    field :image_url, :string
    field :created_by_user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(meeting_room, attrs) do
    meeting_room
    |> cast(attrs, [:name, :location, :capacity, :availability, :status, :features, :image_url])
    |> validate_required([:name, :location, :capacity, :availability, :status, :features, :image_url])
  end
end

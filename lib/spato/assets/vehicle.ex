defmodule Spato.Assets.Vehicle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "vehicles" do
    field :name, :string
    field :status, :string
    field :type, :string
    field :photo_url, :string
    field :vehicle_model, :string
    field :plate_number, :string
    field :capacity, :integer
    field :last_services_at, :date

    belongs_to :user, Spato.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(vehicle, attrs) do
    vehicle
    |> cast(attrs, [:user_id,:name, :type, :photo_url, :vehicle_model, :plate_number, :status, :capacity, :last_services_at])
    |> validate_required([:name, :type, :photo_url, :vehicle_model, :plate_number, :status, :capacity, :last_services_at])
  end
end

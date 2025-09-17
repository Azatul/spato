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
    belongs_to :created_by, Spato.Accounts.User
    has_many :vehicle_bookings, Spato.Bookings.VehicleBooking, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(vehicle, attrs) do
    vehicle
    |> cast(attrs, [:user_id, :created_by_id, :name, :type, :photo_url, :vehicle_model, :plate_number, :status, :capacity, :last_services_at])
    |> validate_required([:name, :type, :vehicle_model, :plate_number, :status, :capacity, :last_services_at])
    |> validate_inclusion(:status, ["tersedia", "dalam_penyelenggaraan"])
    |> unique_constraint(:name, message: "Nama kenderaan sudah digunakan")
    |> unique_constraint(:name, name: :vehicles_name_lower_index, message: "Nama kenderaan sudah digunakan")
  end

  # Map DB values to human-readable labels
  def human_status("tersedia"), do: "Tersedia"
  def human_status("dalam_penyelenggaraan"), do: "Dalam Penyelenggaraan"

  # Catch-all clause for any other value
  def human_status(other), do: other
end

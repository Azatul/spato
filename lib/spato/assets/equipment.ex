defmodule Spato.Assets.Equipment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "equipments" do
    field :name, :string
    field :status, :string
    field :type, :string
    field :photo_url, :string
    field :serial_number, :string
    field :quantity_available, :integer

    belongs_to :user, Spato.Accounts.User
    belongs_to :created_by, Spato.Accounts.User, foreign_key: :created_by_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(equipment, attrs) do
    equipment
    |> cast(attrs, [:name, :type, :photo_url, :serial_number, :quantity_available, :status, :user_id, :created_by_id])
    |> validate_required([:name, :type, :serial_number, :quantity_available, :status])
    |> validate_number(:quantity_available, greater_than_or_equal_to: 0)
    |> validate_inclusion(:status, ["tersedia", "tidak_tersedia"])
  end

  def human_status("tersedia"), do: "Tersedia"
  def human_status("tidak_tersedia"), do: "Tidak Tersedia"
  def human_status(other), do: other
end

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
    field :created_by_user_id, :id
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(equipment, attrs) do
    equipment
    |> cast(attrs, [:name, :type, :photo_url, :serial_number, :quantity_available, :status])
    |> validate_required([:name, :type, :photo_url, :serial_number, :quantity_available, :status])
  end
end

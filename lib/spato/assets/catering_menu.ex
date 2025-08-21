defmodule Spato.Assets.CateringMenu do
  use Ecto.Schema
  import Ecto.Changeset

  schema "catering_menus" do
    field :name, :string
    field :status, :string
    field :type, :string
    field :description, :string
    field :price_per_head, :decimal
    field :photo_url, :string
    belongs_to :created_by_user, Spato.Accounts.User,
      foreign_key: :created_by_user_id,
      type: :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(catering_menu, attrs) do
    catering_menu
    |> cast(attrs, [:name, :type, :description, :price_per_head, :photo_url, :status])
    |> validate_required([:name, :type, :description, :price_per_head, :photo_url, :status])
  end
end

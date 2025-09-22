defmodule Spato.Assets.CateringMenu do
  use Ecto.Schema
  import Ecto.Changeset

  schema "catering_menus" do
    field :name, :string
    field :status, :string
    field :description, :string
    field :price_per_head, :decimal
    field :photo_url, :string
    field :created_by_id, :id
    field :user_id, :id
    field :type, :string

    belongs_to :created_by, Spato.Accounts.User, define_field: false, foreign_key: :created_by_id
    belongs_to :user, Spato.Accounts.User, define_field: false
    has_many :catering_bookings, Spato.Bookings.CateringBooking, foreign_key: :menu_id, on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @spec changeset(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(catering_menu, attrs) do
    catering_menu
    |> cast(attrs, [:name, :type, :description, :price_per_head, :status, :photo_url])
    |> validate_required([:name, :description, :price_per_head, :status])
  end

  def human_type("sarapan"), do: "Sarapan"
  def human_type("makan_tengahari"), do: "Makan Tengahari"
  def human_type("minum_petang"), do: "Minum Petang"
  def human_type(other), do: other


end

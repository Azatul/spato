defmodule Spato.Accounts.Department do
  use Ecto.Schema
  import Ecto.Changeset

  schema "departments" do
    field :code, :string
    field :name, :string

    has_many :user_profiles, Spato.Accounts.UserProfile
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(department, attrs) do
    department
    |> cast(attrs, [:name, :code])
    |> validate_required([:name, :code])
  end
end

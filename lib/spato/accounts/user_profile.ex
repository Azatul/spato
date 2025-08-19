defmodule Spato.Accounts.UserProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_profiles" do
    field :position, :string
    field :address, :string
    field :full_name, :string
    field :dob, :date
    field :ic_number, :string
    field :gender, Ecto.Enum, values: [:male, :female]
    field :phone_number, :string
    field :employment_status, Ecto.Enum, values: [:full_time, :part_time, :contract, :intern]
    field :date_joined, :date
    field :profile_picture_url, :string
    field :last_login_at, :utc_datetime

    belongs_to :user, Spato.Accounts.User
    belongs_to :department, Spato.Accounts.Department

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_profile, attrs) do
    user_profile
    |> cast(attrs, [:full_name, :dob, :ic_number, :gender, :phone_number, :address, :position, :employment_status, :date_joined, :profile_picture_url, :last_login_at, :user_id, :department_id])
    |> validate_required([:full_name, :user_id, :department_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:department)
  end
end

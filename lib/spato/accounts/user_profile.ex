defmodule Spato.Accounts.UserProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_profiles" do
    field :position, :string
    field :address, :string
    field :full_name, :string
    field :dob, :date
    field :ic_number, :string
    field :gender, :string
    field :phone_number, :string
    field :employment_status, :string
    field :date_joined, :date
    field :profile_picture_url, :string
    field :last_login_at, :utc_datetime
    field :is_active, :boolean, default: false
    field :user_id, :id
    field :department_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_profile, attrs) do
    user_profile
    |> cast(attrs, [:full_name, :dob, :ic_number, :gender, :phone_number, :address, :position, :employment_status, :date_joined, :profile_picture_url, :last_login_at, :is_active])
    |> validate_required([:full_name, :dob, :ic_number, :gender, :phone_number, :address, :position, :employment_status, :date_joined, :profile_picture_url, :last_login_at, :is_active])
  end
end

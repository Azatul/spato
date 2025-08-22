defmodule Spato.Accounts.UserProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_profiles" do
    field :position, :string
    field :full_name, :string
    field :dob, :date
    field :ic_number, :string
    field :employment_status, Ecto.Enum, values: [:full_time, :part_time, :contract, :intern]
    field :gender, Ecto.Enum, values: [:male, :female]
    field :date_joined, :date
    field :profile_picture_url, :string
    field :last_seen_at, :utc_datetime
    field :address, :string
    field :phone_number, :string

    belongs_to :department, Spato.Accounts.Department
    belongs_to :user, Spato.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_profile, attrs) do
    user_profile
    |> cast(attrs, [:user_id, :department_id, :full_name, :dob, :ic_number, :position, :gender, :employment_status, :date_joined, :profile_picture_url, :last_seen_at, :address, :phone_number])
    |> validate_required([:full_name, :dob, :ic_number, :position, :gender, :employment_status, :date_joined, :profile_picture_url, :last_seen_at])
  end

  def human_employment_status(:full_time), do: "Sepenuh Masa"
  def human_employment_status(:part_time), do: "Separuh Masa"
  def human_employment_status(:contract), do: "Kontrak"
  def human_employment_status(:intern), do: "Praktikal"
  def human_employment_status(_), do: "Tidak Diketahui"

  def human_gender(:male), do: "Lelaki"
  def human_gender(:female), do: "Perempuan"
  def human_gender(_), do: "Tidak Diketahui"
end

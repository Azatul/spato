defmodule Spato.Bookings.EquipmentBooking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "equipment_bookings" do
    field :status, :string
    field :location, :string
    field :quantity, :integer
    field :usage_date, :date
    field :return_date, :date
    field :usage_time, :time
    field :return_time, :time
    field :additional_notes, :string
    field :condition_before, :string
    field :condition_after, :string

    belongs_to :user, Spato.Accounts.User
    belongs_to :equipment, Spato.Assets.Equipment
    belongs_to :approved_by_user, Spato.Accounts.User
    belongs_to :cancelled_by_user, Spato.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(equipment_booking, attrs) do
    equipment_booking
    |> cast(attrs, [:user_id, :vehicle_id, :approved_by_user_id, :cancelled_by_user_id, :quantity, :location, :usage_date, :return_date, :usage_time, :return_time, :additional_notes, :condition_before, :condition_after, :status])
    |> validate_required([:quantity, :location, :usage_date, :return_date, :usage_time, :return_time, :additional_notes, :condition_before, :condition_after, :status])
  end
end

defmodule Spato.Bookings.EquipmentBooking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "equipment_bookings" do
    field :status, :string
    field :location, :string
    field :requested_quantity, :integer
    field :usage_at, :utc_datetime
    field :return_at, :utc_datetime
    field :additional_notes, :string
    field :condition_before, :string
    field :condition_after, :string
    field :rejection_reason, :string

    belongs_to :user, Spato.Accounts.User
    belongs_to :equipment, Spato.Assets.Equipment
    belongs_to :approved_by_user, Spato.Accounts.User
    belongs_to :cancelled_by_user, Spato.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(equipment_booking, attrs) do
    equipment_booking
    |> cast(attrs, [:user_id, :equipment_id, :approved_by_user_id, :cancelled_by_user_id, :requested_quantity, :location, :usage_at, :return_at, :additional_notes, :condition_before, :condition_after, :status])
    |> validate_required([:requested_quantity, :location, :usage_at, :return_at, :additional_notes, :status])
    |> validate_inclusion(:status, ["pending", "approved", "rejected", "cancelled", "completed"])
    |> unique_constraint(:equipment_id, name: :no_overlapping_bookings)
    |> update_change(:status, &String.downcase/1)
    |> validate_equipment_quantity()
  end

  defp validate_equipment_quantity(changeset) do
    case {get_field(changeset, :equipment_id), get_field(changeset, :requested_quantity)} do
      {nil, _} -> changeset
      {_, nil} -> changeset
      {equipment_id, requested_quantity} ->
        case Spato.Repo.get(Spato.Assets.Equipment, equipment_id) do
          nil -> changeset
          equipment ->
            if requested_quantity > equipment.available_quantity do
              add_error(changeset, :requested_quantity,
                "Jumlah peralatan melebihi stok tersedia (#{equipment.available_quantity})"
              )
            else
              changeset
            end
        end
    end
  end

  def human_status("pending"), do: "Menunggu Kelulusan"
  def human_status("approved"), do: "Diluluskan"
  def human_status("rejected"), do: "Ditolak"
  def human_status("cancelled"), do: "Dibatalkan"
  def human_status("completed"), do: "Selesai"
  def human_status(other), do: other
end

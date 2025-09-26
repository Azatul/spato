defmodule Spato.Bookings.EquipmentBooking do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Spato.Repo

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
    |> cast(attrs, [:user_id, :equipment_id, :approved_by_user_id, :cancelled_by_user_id, :requested_quantity, :location, :usage_at, :return_at, :additional_notes, :condition_before, :condition_after, :status, :rejection_reason])
    |> validate_required([:requested_quantity, :location, :usage_at, :return_at, :additional_notes, :status])
    |> validate_inclusion(:status, ["pending", "approved", "rejected", "cancelled", "completed"])
    |> unique_constraint(:equipment_id, name: :no_overlapping_bookings)
    |> update_change(:status, &String.downcase/1)
    |> validate_equipment_quantity()
    |> Spato.Bookings.validate_datetime_order(:usage_at, :return_at)
  end

  defp validate_equipment_quantity(changeset) do
    equipment_id        = get_field(changeset, :equipment_id)
    requested_quantity  = get_field(changeset, :requested_quantity)
    usage_at            = get_field(changeset, :usage_at)
    return_at           = get_field(changeset, :return_at)

    cond do
      is_nil(equipment_id) -> changeset
      is_nil(requested_quantity) -> changeset
      is_nil(usage_at) or is_nil(return_at) -> changeset
      true ->
        case Repo.get(Spato.Assets.Equipment, equipment_id) do
          nil -> changeset
          equipment ->
            # Sum of overlapping bookings (pending/approved) excluding current record when editing
            base_query =
              from b in __MODULE__,
                where:
                  b.equipment_id == ^equipment_id and
                  b.status in ["pending", "approved"] and
                  b.usage_at < ^return_at and
                  b.return_at > ^usage_at

            base_query =
              case changeset.data && changeset.data.id do
                nil -> base_query
                current_id -> from b in base_query, where: b.id != ^current_id
              end

            already_booked = Repo.one(from b in base_query, select: sum(b.requested_quantity)) || 0
            remaining = (equipment.total_quantity || 0) - already_booked

            if requested_quantity > remaining do
              add_error(changeset, :requested_quantity,
                "Jumlah peralatan melebihi stok tersedia (#{max(remaining, 0)})"
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

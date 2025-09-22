defmodule Spato.Bookings.EquipmentBooking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "equipment_bookings" do
    field :status, :string, default: "pending"
    field :location, :string
    field :quantity, :integer

    # old fields (still here for compatibility)
    field :usage_date, :date
    field :return_date, :date
    field :usage_time, :time
    field :return_time, :time

    # new fields (cleaner datetime versions)
    field :usage_at, :utc_datetime
    field :return_at, :utc_datetime

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
    |> cast(attrs, [
      :user_id,
      :equipment_id,
      :approved_by_user_id,
      :cancelled_by_user_id,
      :quantity,
      :location,
      :usage_date,
      :return_date,
      :usage_time,
      :return_time,
      :usage_at,
      :return_at,
      :additional_notes,
      :condition_before,
      :condition_after,
      :status
    ])
    |> validate_required([
      :quantity,
      :location,
      :usage_date,
      :return_date,
      :usage_time,
      :return_time
    ])
    |> validate_inclusion(:status, ["pending", "approved", "rejected", "cancelled", "completed"])
    |> update_change(:status, &String.downcase/1)
    |> put_usage_and_return_at(attrs)   # derive usage_at/return_at from date+time fields
  end

  # Helpers
  defp put_usage_and_return_at(changeset, attrs) do
    usage_at =
      with d when d not in [nil, ""] <- attrs["usage_date"] || attrs[:usage_date],
           t when t not in [nil, ""] <- attrs["usage_time"] || attrs[:usage_time],
           {:ok, date} <- cast_to_date(d),
           {:ok, time} <- cast_to_time(t) do
        DateTime.new!(date, time, "Etc/UTC")
      else
        _ -> nil
      end

    return_at =
      with d when d not in [nil, ""] <- attrs["return_date"] || attrs[:return_date],
           t when t not in [nil, ""] <- attrs["return_time"] || attrs[:return_time],
           {:ok, date} <- cast_to_date(d),
           {:ok, time} <- cast_to_time(t) do
        DateTime.new!(date, time, "Etc/UTC")
      else
        _ -> nil
      end

    changeset
    |> put_change(:usage_at, usage_at)
    |> put_change(:return_at, return_at)
  end

  defp cast_to_date(%Date{} = date), do: {:ok, date}
  defp cast_to_date(d) when is_binary(d), do: Date.from_iso8601(d)
  defp cast_to_date(_), do: :error

  defp cast_to_time(%Time{} = time), do: {:ok, time}
  defp cast_to_time(t) when is_binary(t), do: Time.from_iso8601(t)
  defp cast_to_time(_), do: :error

  # Human-friendly status labels
  def human_status("pending"), do: "Menunggu Kelulusan"
  def human_status("approved"), do: "Diluluskan"
  def human_status("rejected"), do: "Ditolak"
  def human_status("cancelled"), do: "Dibatalkan"
  def human_status("completed"), do: "Selesai"
  def human_status(other), do: other
end

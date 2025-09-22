defmodule Spato.Bookings.CateringBooking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "catering_bookings" do
    field :status, :string
    field :date, :date
    field :time, :time
    field :location, :string
    field :participants, :integer
    field :total_cost, :decimal
    field :special_request, :string

    belongs_to :user, Spato.Accounts.User
    belongs_to :menu, Spato.Assets.CateringMenu
    belongs_to :approved_by_user, Spato.Accounts.User
    belongs_to :cancelled_by_user, Spato.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(catering_booking, attrs) do
    attrs =
      if Map.has_key?(attrs, "number_of_people") do
        Map.put(attrs, "participants", attrs["number_of_people"])
      else
        attrs
      end

    catering_booking
    |> cast(attrs, [:date, :time, :location, :participants, :total_cost, :special_request, :status, :menu_id, :user_id])
    |> validate_required([:date, :status, :menu_id, :user_id])
    |> validate_inclusion(:status, ["pending", "approved", "rejected", "cancelled", "completed"])
    |> validate_number(:participants, greater_than: 0)
    |> update_change(:status, &String.downcase/1)
  end


  def human_status("pending"), do: "Menunggu Kelulusan"
  def human_status("approved"), do: "Diluluskan"
  def human_status("rejected"), do: "Ditolak"
  def human_status("cancelled"), do: "Dibatalkan"
  def human_status("completed"), do: "Selesai"
  def human_status(other), do: other

end

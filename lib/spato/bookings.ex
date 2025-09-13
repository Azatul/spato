defmodule Spato.Bookings do
  @moduledoc """
  The Bookings context for managing vehicle bookings.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo
  alias Spato.Bookings.VehicleBooking

  @per_page 10

  # --- Listing ---

  def list_vehicle_bookings(user \\ nil) do
    VehicleBooking
    |> scope_by_user(user)
    |> order_by([vb], desc: vb.inserted_at)
    |> preload([:vehicle, user: [:user_profile]])
    |> Repo.all()
  end

  def list_vehicle_bookings_paginated(params \\ %{}, user \\ nil) do
    page   = Map.get(params, "page", 1) |> to_int()
    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")
    date   = Map.get(params, "date", "")
    per_page = @per_page
    offset = (page - 1) * per_page

    # Base query
    base_query =
      from vb in VehicleBooking,
        order_by: [desc: vb.inserted_at]

    # Scope to current user if provided
    scoped_query =
      case user do
        nil -> base_query
        _ -> from vb in base_query, where: vb.user_id == ^user.id
      end

    # Status filter
    status_query =
      if status != "all" do
        from vb in scoped_query, where: vb.status == ^status
      else
        scoped_query
      end

    # Date filter
    date_query =
      if date != "" do
        case Date.from_iso8601(date) do
          {:ok, parsed} ->
            from vb in status_query,
              where:
                fragment("date(?)", vb.pickup_time) == ^parsed or
                fragment("date(?)", vb.return_time) == ^parsed

          _ -> status_query
        end
      else
        status_query
      end

    # Search filter
    final_query =
      if search != "" do
        like_search = "%#{search}%"

        from vb in date_query,
          left_join: u in assoc(vb, :user),
          left_join: up in assoc(u, :user_profile),
          where:
            ilike(vb.purpose, ^like_search) or
            ilike(vb.trip_destination, ^like_search) or
            ilike(vb.status, ^like_search) or
            ilike(u.email, ^like_search) or
            ilike(up.full_name, ^like_search),
          distinct: vb.id,
          select: vb
      else
        date_query
      end

    # Total count
    total =
      final_query
      |> exclude(:order_by)
      |> Repo.aggregate(:count, :id)

    # Paginated results with preload
    vehicle_bookings_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload(user: [:user_profile])
      |> Repo.preload([:vehicle, user: [:user_profile]])

    total_pages = ceil(total / per_page)

    %{
      vehicle_bookings_page: vehicle_bookings_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  def available_vehicles(filters) do
    import Ecto.Query

    pickup_time = filters["pickup_time"]
    return_time = filters["return_time"]

    base_query =
      from v in Spato.Assets.Vehicle,
        preload: [:vehicle_bookings]

    # If no pickup/return time provided, just return all
    if is_nil(pickup_time) or is_nil(return_time) do
      Spato.Repo.all(base_query)
    else
      from(v in base_query,
        left_join: b in assoc(v, :vehicle_bookings),
        on:
          b.vehicle_id == v.id and
            b.status in ["pending", "approved"] and
            fragment(
              "tsrange(?, ?) && tsrange(?, ?)",
              b.pickup_time,
              b.return_time,
              ^pickup_time,
              ^return_time
            ),
        where: is_nil(b.id)
      )
      |> Spato.Repo.all()
    end
  end

  # --- CRUD ---

  def get_vehicle_booking!(id) do
    Repo.get!(VehicleBooking, id)
    |> Repo.preload([
      :vehicle,
      :user,
      :approved_by_user,
      :cancelled_by_user
    ])
  end

  def create_vehicle_booking(attrs) do
    %VehicleBooking{}
    |> VehicleBooking.changeset(attrs)
    |> Repo.insert()
  end

  def update_vehicle_booking(%VehicleBooking{} = vb, attrs) do
    vb
    |> VehicleBooking.changeset(attrs)
    |> Repo.update()
  end

  def delete_vehicle_booking(%VehicleBooking{} = vb), do: Repo.delete(vb)

  def change_vehicle_booking(%VehicleBooking{} = vb, attrs \\ %{}) do
    VehicleBooking.changeset(vb, attrs)
  end

  # --- Actions ---

  def approve_booking(%VehicleBooking{} = vb),
    do: update_vehicle_booking(vb, %{status: "approved"})

  def reject_booking(%VehicleBooking{} = vb),
    do: update_vehicle_booking(vb, %{status: "rejected"})

  def cancel_booking(%VehicleBooking{} = vb, %Spato.Accounts.User{} = user) do
    case vb.status do
      "pending" ->
        update_vehicle_booking(vb, %{status: "cancelled", cancelled_by_user_id: user.id})

      _ ->
        {:error, :not_allowed}
    end
  end

  # --- Private Helpers ---

  defp scope_by_user(query, nil), do: query
  defp scope_by_user(query, user),
    do: (from vb in query, where: vb.user_id == ^user.id)

  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val), do: String.to_integer(val)
  defp to_int(_), do: 1
end

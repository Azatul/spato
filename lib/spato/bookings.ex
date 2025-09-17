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
    |> preload([:vehicle, user: [user_profile: [:department]]])
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
          left_join: d in assoc(up, :department),
          left_join: v in assoc(vb, :vehicle),
          where:
            ilike(vb.purpose, ^like_search) or
            ilike(vb.trip_destination, ^like_search) or
            ilike(vb.status, ^like_search) or
            ilike(u.email, ^like_search) or
            ilike(v.name, ^like_search) or
            ilike(v.plate_number, ^like_search) or
            ilike(v.type, ^like_search) or
            ilike(v.vehicle_model, ^like_search) or
            ilike(up.full_name, ^like_search) or
            ilike(d.name, ^like_search),
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
      |> Repo.preload([:vehicle, user: [user_profile: [:department]]])
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

    query    = filters["query"]
    type     = filters["type"]
    capacity = filters["capacity"]
    page     = Map.get(filters, "page", 1) |> to_int()
    per_page = 12
    offset   = (page - 1) * per_page

    # Parse pickup & return times using helper
    pickup_time = parse_datetime(filters["pickup_time"])
    return_time = parse_datetime(filters["return_time"])

    # Base query – only vehicles with status "tersedia"
    base_query =
      from v in Spato.Assets.Vehicle,
        preload: [:vehicle_bookings],
        where: v.status == "tersedia"

    # Type filter
    base_query =
      if type && type != "all" do
        from v in base_query, where: v.type == ^String.downcase(type)
      else
        base_query
      end

    # Capacity filter
    base_query =
      if capacity not in [nil, ""] do
        case Integer.parse(capacity) do
          {cap, _} -> from v in base_query, where: v.capacity >= ^cap
          :error -> base_query
        end
      else
        base_query
      end

    # Search filter
    base_query =
      if query not in [nil, ""] do
        like_q = "%#{query}%"
        from v in base_query,
          where:
            ilike(v.name, ^like_q) or
            ilike(v.plate_number, ^like_q) or
            ilike(v.vehicle_model, ^like_q)
      else
        base_query
      end

    # Availability filter – hide vehicles with conflicting bookings
    final_query =
      if pickup_time && return_time do
        from v in base_query,
          as: :vehicle,
          where: not exists(
            from b in Spato.Bookings.VehicleBooking,
              where:
                b.vehicle_id == parent_as(:vehicle).id and
                b.status in ["pending", "approved"] and
                b.pickup_time < ^return_time and
                b.return_time > ^pickup_time
          )
      else
        # If no valid dates, just show all available vehicles
        base_query
      end

    # Total count & pagination
    total = final_query |> exclude(:order_by) |> Repo.aggregate(:count, :id)
    total_pages = ceil(total / per_page)

    vehicles_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    %{
      vehicles_page: vehicles_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  defp parse_datetime(nil), do: nil
  defp parse_datetime(""), do: nil
  defp parse_datetime(val) do
    case NaiveDateTime.from_iso8601(val) do
      {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
      _ ->
        case NaiveDateTime.from_iso8601(val <> ":00") do
          {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
          _ -> nil
        end
    end
  end

  # --- CRUD ---

  def get_vehicle_booking!(id) do
    Repo.get!(VehicleBooking, id)
    |> Repo.preload([
      :vehicle,
      [user: [user_profile: [:department]]],
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

  import Ecto.Query

  def get_booking_stats do
    now = DateTime.utc_now()

    total = Repo.aggregate(VehicleBooking, :count, :id)
    pending = Repo.aggregate(from(v in VehicleBooking, where: v.status == "pending"), :count, :id)
    approved = Repo.aggregate(from(v in VehicleBooking, where: v.status == "approved"), :count, :id)

    # Active = approved and current time between pickup and return
    active =
      Repo.aggregate(
        from(v in VehicleBooking,
          where: v.status == "approved" and
                 v.pickup_time <= ^now and
                 v.return_time >= ^now
        ),
        :count,
        :id
      )

    %{
      total: total,
      pending: pending,
      approved: approved,
      active: active
    }
  end

  def get_user_booking_stats(user_id) do
    now = Date.utc_today()
    # Get the weekday (1 = Monday, 7 = Sunday)
    weekday = Date.day_of_week(now)
    # Beginning of week (Monday)
    beginning_of_week = Date.add(now, -weekday + 1)
    # End of week (Sunday)
    end_of_week = Date.add(beginning_of_week, 6)

    # Convert to DateTime in UTC
    {:ok, beginning_of_week_dt} = DateTime.new(beginning_of_week, ~T[00:00:00], "Etc/UTC")
    {:ok, end_of_week_dt} = DateTime.new(end_of_week, ~T[23:59:59], "Etc/UTC")

    base_query =
      from vb in VehicleBooking,
        where: vb.user_id == ^user_id and vb.inserted_at >= ^beginning_of_week_dt and vb.inserted_at <= ^end_of_week_dt

    %{
      total: Repo.aggregate(base_query, :count, :id),
      pending: Repo.aggregate(from(vb in base_query, where: vb.status == "pending"), :count, :id),
      approved: Repo.aggregate(from(vb in base_query, where: vb.status == "approved"), :count, :id),
      rejected: Repo.aggregate(from(vb in base_query, where: vb.status == "rejected"), :count, :id),
      completed: Repo.aggregate(from(vb in base_query, where: vb.status == "completed"), :count, :id)
    }
  end

end

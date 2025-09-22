defmodule Spato.Bookings do
  @moduledoc """
  The Bookings context for managing vehicle and equipment bookings.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo

  alias Spato.Bookings.VehicleBooking
  alias Spato.Bookings.EquipmentBooking

  @per_page 10

  # ===================================================================
  # --- VEHICLE BOOKINGS ---
  # ===================================================================

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

  def get_vehicle_booking!(id) do
    Repo.get!(VehicleBooking, id)
    |> Repo.preload([
      :vehicle,
      [user: [user_profile: [:department]]],
      :approved_by_user,
      :cancelled_by_user
    ])
  end

  def create_vehicle_booking(attrs), do: %VehicleBooking{} |> VehicleBooking.changeset(attrs) |> Repo.insert()
  def update_vehicle_booking(%VehicleBooking{} = vb, attrs), do: vb |> VehicleBooking.changeset(attrs) |> Repo.update()
  def delete_vehicle_booking(%VehicleBooking{} = vb), do: Repo.delete(vb)
  def change_vehicle_booking(%VehicleBooking{} = vb, attrs \\ %{}), do: VehicleBooking.changeset(vb, attrs)

  # Actions
  def approve_booking(%VehicleBooking{} = vb), do: update_vehicle_booking(vb, %{status: "approved"})
  def reject_booking(%VehicleBooking{} = vb), do: update_vehicle_booking(vb, %{status: "rejected"})

  def cancel_booking(%VehicleBooking{} = vb, %Spato.Accounts.User{} = user) do
    case vb.status do
      "pending" -> update_vehicle_booking(vb, %{status: "cancelled", cancelled_by_user_id: user.id})
      _ -> {:error, :not_allowed}
    end
  end

  # Stats
  def get_booking_stats do
    now = DateTime.utc_now()

    total = Repo.aggregate(VehicleBooking, :count, :id)
    pending = Repo.aggregate(from(v in VehicleBooking, where: v.status == "pending"), :count, :id)
    approved = Repo.aggregate(from(v in VehicleBooking, where: v.status == "approved"), :count, :id)

    # Active = approved and current time between pickup and return
    active =
      Repo.aggregate(
        from(v in VehicleBooking,
          where: v.status == "approved" and v.pickup_time <= ^now and v.return_time >= ^now
        ),
        :count,
        :id
      )

    %{total: total, pending: pending, approved: approved, active: active}
  end

  def get_user_booking_stats(user_id) do
    now = Date.utc_today()
    weekday = Date.day_of_week(now)
    beginning_of_week = Date.add(now, -weekday + 1)
    end_of_week = Date.add(beginning_of_week, 6)

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

  # ===================================================================
  # --- EQUIPMENT BOOKINGS ---
  # ===================================================================

  def list_equipment_bookings(user \\ nil) do
    EquipmentBooking
    |> scope_by_user(user)
    |> order_by([eb], desc: eb.inserted_at)
    |> preload([:equipment, user: [user_profile: [:department]]])
    |> Repo.all()
  end

  def list_equipment_bookings_paginated(params \\ %{}, user \\ nil) do
    page   = Map.get(params, "page", 1) |> to_int()
    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")
    date   = Map.get(params, "date", "")
    per_page = @per_page
    offset = (page - 1) * per_page

    base_query =
      from eb in EquipmentBooking,
        order_by: [desc: eb.inserted_at]

    scoped_query =
      case user do
        nil -> base_query
        _ -> from eb in base_query, where: eb.user_id == ^user.id
      end

    status_query =
      if status != "all" do
        from eb in scoped_query, where: eb.status == ^status
      else
        scoped_query
      end

    date_query =
      if date != "" do
        case Date.from_iso8601(date) do
          {:ok, parsed} ->
            from eb in status_query,
              where:
                fragment("date(?)", eb.usage_at) == ^parsed or
                fragment("date(?)", eb.return_at) == ^parsed

          _ -> status_query
        end
      else
        status_query
      end

    final_query =
      if search != "" do
        like_search = "%#{search}%"

        from eb in date_query,
          left_join: u in assoc(eb, :user),
          left_join: up in assoc(u, :user_profile),
          left_join: d in assoc(up, :department),
          left_join: e in assoc(eb, :equipment),
          where:
            ilike(eb.location, ^like_search) or
            ilike(eb.status, ^like_search) or
            ilike(u.email, ^like_search) or
            ilike(e.name, ^like_search) or
            ilike(e.serial_number, ^like_search) or
            ilike(up.full_name, ^like_search) or
            ilike(d.name, ^like_search),
          distinct: eb.id,
          select: eb
      else
        date_query
      end

    total =
      final_query
      |> exclude(:order_by)
      |> Repo.aggregate(:count, :id)

    equipment_bookings_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload([:equipment, user: [user_profile: [:department]]])

    total_pages = ceil(total / per_page)

    %{
      equipment_bookings_page: equipment_bookings_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  def available_equipments(filters) do
    import Ecto.Query

    query    = filters["query"]
    type     = filters["type"]
    quantity = filters["quantity"]
    page     = Map.get(filters, "page", 1) |> to_int()
    per_page = 12
    offset   = (page - 1) * per_page

    usage_dt  = parse_datetime(filters["usage_at"])
    return_dt = parse_datetime(filters["return_at"])

    # Base query – only available equipments
    base_query =
      from e in Spato.Assets.Equipment,
        where: e.status == "tersedia"

    # Type filter
    base_query =
      if type && type != "all" do
        from e in base_query, where: e.type == ^String.downcase(type)
      else
        base_query
      end

    # Search filter
    base_query =
      if query not in [nil, ""] do
        like_q = "%#{query}%"
        from e in base_query,
          where: ilike(e.name, ^like_q) or
                 ilike(e.serial_number, ^like_q) or
                 ilike(e.type, ^like_q)
      else
        base_query
      end

    # Parse requested quantity
    requested_qty =
      case quantity do
        q when q in [nil, ""] -> 1
        q when is_binary(q) -> case Integer.parse(q) do {v, _} -> v; :error -> 1 end
      end

    # Handle availability based on usage/return datetime
    final_query =
      if usage_dt && return_dt do
        overlap_reserved =
          from b in EquipmentBooking,
            where: b.status in ["pending", "approved"] and
                   b.usage_at < ^return_dt and
                   b.return_at > ^usage_dt,
            group_by: b.equipment_id,
            select: %{equipment_id: b.equipment_id, reserved_quantity: sum(b.quantity)}

        from e in base_query,
          left_join: r in subquery(overlap_reserved), on: r.equipment_id == e.id,
          where: (e.quantity - coalesce(r.reserved_quantity, 0)) >= ^requested_qty,
          select_merge: %{quantity_available: e.quantity - coalesce(r.reserved_quantity, 0)}
      else
        # No dates selected – show all available equipments
        from e in base_query,
          select_merge: %{quantity_available: e.quantity}
      end

    # Pagination
    total = final_query |> exclude(:order_by) |> Repo.aggregate(:count, :id)
    total_pages = ceil(total / per_page)

    equipments_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    %{
      equipments_page: equipments_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  def get_equipment_booking!(id) do
    Repo.get!(EquipmentBooking, id)
    |> Repo.preload([
      :equipment,
      [user: [user_profile: [:department]]],
      :approved_by_user,
      :cancelled_by_user
    ])
  end

  def create_equipment_booking(attrs) do
    %EquipmentBooking{}
    |> EquipmentBooking.changeset(attrs)
    |> Repo.insert()
  end

  def complete_equipment_booking(%EquipmentBooking{} = booking) do
    update_equipment_booking(booking, %{status: "completed"})
  end

  def cancel_equipment_booking(%EquipmentBooking{} = booking, %Spato.Accounts.User{} = user) do
    case booking.status do
      "pending" ->
        update_equipment_booking(booking, %{status: "cancelled", cancelled_by_user_id: user.id})

      _ -> {:error, :not_allowed}
    end
  end

  def update_equipment_booking(%EquipmentBooking{} = eb, attrs), do: eb |> EquipmentBooking.changeset(attrs) |> Repo.update()
  def delete_equipment_booking(%EquipmentBooking{} = eb), do: Repo.delete(eb)
  def change_equipment_booking(%EquipmentBooking{} = eb, attrs \\ %{}), do: EquipmentBooking.changeset(eb, attrs)

  def approve_equipment_booking(%EquipmentBooking{} = booking) do
    update_equipment_booking(booking, %{status: "approved"})
  end

  def reject_equipment_booking(%EquipmentBooking{} = booking) do
    alias Spato.Assets.Equipment

    Ecto.Multi.new()
    |> Ecto.Multi.update(:booking, EquipmentBooking.changeset(booking, %{status: "rejected"}))
    |> Ecto.Multi.run(:restore_equipment, fn repo, %{booking: booking} ->
      equipment = repo.get!(Equipment, booking.equipment_id)
      new_qty = equipment.quantity_available + booking.quantity
      equipment
      |> Ecto.Changeset.change(%{quantity_available: new_qty})
      |> repo.update()
    end)
    |> Repo.transaction()
  end

  def get_equipment_booking_stats do
    now = DateTime.utc_now()

    total = Repo.aggregate(EquipmentBooking, :count, :id)
    pending = Repo.aggregate(from(e in EquipmentBooking, where: e.status == "pending"), :count, :id)
    approved = Repo.aggregate(from(e in EquipmentBooking, where: e.status == "approved"), :count, :id)

    active =
      Repo.aggregate(
        from(e in EquipmentBooking,
          where: e.status == "approved" and e.usage_at <= ^now and e.return_at >= ^now
        ),
        :count,
        :id
      )

    %{total: total, pending: pending, approved: approved, active: active}
  end

  def get_user_equipment_booking_stats(user_id) do
    now = Date.utc_today()
    weekday = Date.day_of_week(now)
    beginning_of_week = Date.add(now, -weekday + 1)
    end_of_week = Date.add(beginning_of_week, 6)

    {:ok, beginning_of_week_dt} = DateTime.new(beginning_of_week, ~T[00:00:00], "Etc/UTC")
    {:ok, end_of_week_dt} = DateTime.new(end_of_week, ~T[23:59:59], "Etc/UTC")

    base_query =
      from eb in EquipmentBooking,
        where:
          eb.user_id == ^user_id and
          eb.usage_at >= ^beginning_of_week_dt and
          eb.return_at <= ^end_of_week_dt

    %{
      total: Repo.aggregate(base_query, :count, :id),
      pending: Repo.aggregate(from(eb in base_query, where: eb.status == "pending"), :count, :id),
      approved: Repo.aggregate(from(eb in base_query, where: eb.status == "approved"), :count, :id),
      rejected: Repo.aggregate(from(eb in base_query, where: eb.status == "rejected"), :count, :id),
      completed: Repo.aggregate(from(eb in base_query, where: eb.status == "completed"), :count, :id)
    }
  end

  # ===================================================================
  # --- PRIVATE HELPERS ---
  # ===================================================================

  defp scope_by_user(query, nil), do: query
  defp scope_by_user(query, user), do: (from b in query, where: b.user_id == ^user.id)

  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val), do: String.to_integer(val)
  defp to_int(_), do: 1

  defp parse_datetime(nil), do: nil
  defp parse_datetime(""), do: nil
  defp parse_datetime(val) do
    case NaiveDateTime.from_iso8601(val) do
      {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
      _ -> nil
    end
  end
end

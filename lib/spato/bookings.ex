defmodule Spato.Bookings do
  @moduledoc """
  The Bookings context for managing vehicle bookings and catering bookings.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo
  alias Spato.Bookings.VehicleBooking
  alias Spato.Bookings.CateringBooking

  @per_page 10

  # --- Vehicle Booking Listing ---

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

  # --- Catering Booking Listing ---

  def list_catering_bookings(user \\ nil) do
    CateringBooking
    |> scope_catering_by_user(user)
    |> order_by([cb], desc: cb.inserted_at)
    |> preload([:menu, user: [user_profile: [:department]]])
    |> Repo.all()
  end

  def list_catering_bookings_paginated(params \\ %{}, user \\ nil) do
    page   = Map.get(params, "page", 1) |> to_int()
    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")
    date   = Map.get(params, "date", "")
    per_page = @per_page
    offset = (page - 1) * per_page

    # Base query
    base_query =
      from cb in CateringBooking,
        order_by: [desc: cb.inserted_at]

    # Scope to current user if provided
    scoped_query =
      case user do
        nil -> base_query
        _ -> from cb in base_query, where: cb.user_id == ^user.id
      end

    # Status filter
    status_query =
      if status != "all" do
        from cb in scoped_query, where: cb.status == ^status
      else
        scoped_query
      end

    # Date filter
    date_query =
      if date != "" do
        case Date.from_iso8601(date) do
          {:ok, parsed} ->
            from cb in status_query,
              where: cb.date == ^parsed

          _ -> status_query
        end
      else
        status_query
      end

    # Search filter
    final_query =
      if search != "" do
        like_search = "%#{search}%"

        from cb in date_query,
          left_join: u in assoc(cb, :user),
          left_join: up in assoc(u, :user_profile),
          left_join: d in assoc(up, :department),
          left_join: m in assoc(cb, :menu),
          where:
            ilike(cb.location, ^like_search) or
            ilike(cb.special_request, ^like_search) or
            ilike(cb.status, ^like_search) or
            ilike(u.email, ^like_search) or
            ilike(m.name, ^like_search) or
            ilike(m.description, ^like_search) or
            ilike(up.full_name, ^like_search) or
            ilike(d.name, ^like_search),
          distinct: cb.id,
          select: cb
      else
        date_query
      end

    # Total count
    total =
      final_query
      |> exclude(:order_by)
      |> Repo.aggregate(:count, :id)

    # Paginated results with preload
    catering_bookings_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload([:menu, user: [user_profile: [:department]]])
    total_pages = ceil(total / per_page)

    %{
      catering_bookings_page: catering_bookings_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  def available_catering_menus(filters) do
    import Ecto.Query

    query    = filters["query"]
    type     = filters["type"]
    page     = Map.get(filters, "page", 1) |> to_int()
    per_page = 12
    offset   = (page - 1) * per_page

    # Base query – only menus with status "tersedia"
    base_query =
      from m in Spato.Assets.CateringMenu,
        where: m.status == "tersedia"

    # Type filter
    base_query =
      if type && type != "all" do
        from m in base_query, where: m.type == ^String.downcase(type)
      else
        base_query
      end

    # Search filter
    base_query =
      if query not in [nil, ""] do
        like_q = "%#{query}%"
        from m in base_query,
          where:
            ilike(m.name, ^like_q) or
            ilike(m.description, ^like_q)
      else
        base_query
      end

    # Total count & pagination
    total = base_query |> exclude(:order_by) |> Repo.aggregate(:count, :id)
    total_pages = ceil(total / per_page)

    menus_page =
      base_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    %{
      menus_page: menus_page,
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

  # --- Vehicle Booking CRUD ---

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

  def update_booking_status(%VehicleBooking{} = booking, status, reason \\ nil) do
    attrs =
      if status == "rejected" and reason do
        %{status: "rejected", rejection_reason: reason}
      else
        %{status: status}
      end

    booking
    |> VehicleBooking.changeset(attrs)
    |> Repo.update()
  end

  def delete_vehicle_booking(%VehicleBooking{} = vb), do: Repo.delete(vb)

  def change_vehicle_booking(%VehicleBooking{} = vb, attrs \\ %{}) do
    VehicleBooking.changeset(vb, attrs)
  end

  # --- Catering Booking CRUD ---

  def get_catering_booking!(id) do
    Repo.get!(CateringBooking, id)
    |> Repo.preload([
      :menu,
      [user: [user_profile: [:department]]],
      :approved_by_user,
      :cancelled_by_user
    ])
  end

  def create_catering_booking(attrs \\ %{}) do
    %CateringBooking{}
    |> CateringBooking.changeset(attrs)
    |> Repo.insert()
  end

  def update_catering_booking(%CateringBooking{} = cb, attrs) do
    cb
    |> CateringBooking.changeset(attrs)
    |> Repo.update()
  end

  def delete_catering_booking(%CateringBooking{} = cb) do
    Repo.delete(cb)
  end

  def change_catering_booking(%CateringBooking{} = cb, attrs \\ %{}) do
    CateringBooking.changeset(cb, attrs)
  end

  # --- Vehicle Booking Actions ---

  def approve_booking(%VehicleBooking{} = vb),
    do: update_vehicle_booking(vb, %{status: "approved"})

  def reject_booking(%VehicleBooking{} = vb, reason \\ nil) do
    update_vehicle_booking(vb, %{status: "rejected", rejection_reason: reason})
  end

  def cancel_booking(%VehicleBooking{} = vb, %Spato.Accounts.User{} = user, reason \\ nil) do
    case vb.status do
      "pending" ->
        update_vehicle_booking(vb, %{status: "cancelled", cancelled_by_user_id: user.id, rejection_reason: reason})

      "approved" ->
        update_vehicle_booking(vb, %{status: "cancelled", cancelled_by_user_id: user.id, rejection_reason: reason})

      _ ->
        {:error, :not_allowed}
    end
  end

  # --- Catering Booking Actions ---

  def approve_catering_booking(%CateringBooking{} = cb, %Spato.Accounts.User{} = user) do
    update_catering_booking(cb, %{status: "approved", approved_by_user_id: user.id})
  end

  def reject_catering_booking(%CateringBooking{} = cb, %Spato.Accounts.User{} = user, reason \\ nil) do
    update_catering_booking(cb, %{
      status: "rejected",
      approved_by_user_id: user.id,
      rejection_reason: reason
    })
  end

  def cancel_catering_booking(%CateringBooking{} = cb, %Spato.Accounts.User{} = user, reason \\ nil) do
    case cb.status do
      "pending" ->
        update_catering_booking(cb, %{
          status: "cancelled",
          cancelled_by_user_id: user.id,
          rejection_reason: reason
        })

      "approved" ->
        update_catering_booking(cb, %{
          status: "cancelled",
          cancelled_by_user_id: user.id,
          rejection_reason: reason
        })

      _ ->
        {:error, :not_allowed}
    end
  end

  def complete_catering_booking(%CateringBooking{} = cb) do
    update_catering_booking(cb, %{status: "completed"})
  end

  # --- Private Helpers ---

  defp scope_by_user(query, nil), do: query
  defp scope_by_user(query, user),
    do: (from vb in query, where: vb.user_id == ^user.id)

  defp scope_catering_by_user(query, nil), do: query
  defp scope_catering_by_user(query, user),
    do: (from cb in query, where: cb.user_id == ^user.id)

  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val), do: String.to_integer(val)
  defp to_int(_), do: 1

  import Ecto.Query

  # --- Statistics ---

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

  def get_catering_booking_stats do
    now = Date.utc_today()

    total = Repo.aggregate(CateringBooking, :count, :id)
    pending = Repo.aggregate(from(c in CateringBooking, where: c.status == "pending"), :count, :id)
    approved = Repo.aggregate(from(c in CateringBooking, where: c.status == "approved"), :count, :id)

    # Active = approved and date is today or future
    active =
      Repo.aggregate(
        from(c in CateringBooking,
          where: c.status == "approved" and
                 c.date >= ^now
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


  alias Spato.Bookings.EquipmentBooking

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

    def available_equipment(filters) do
      import Ecto.Query

      query    = filters["query"]
      type     = filters["type"]
      page     = Map.get(filters, "page", 1) |> to_int()
      per_page = 12
      offset   = (page - 1) * per_page

      usage_at  = parse_datetime(filters["usage_at"])
      return_at = parse_datetime(filters["return_at"])

      # Base query – only equipment with status "tersedia"
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
            where: ilike(e.name, ^like_q) or ilike(e.serial_number, ^like_q)
        else
          base_query
        end

      # Availability filter – check overlapping bookings and remaining quantity
      final_query =
        if usage_at && return_at do
          from e in base_query,
            left_join: b in Spato.Bookings.EquipmentBooking,
            on:
              b.equipment_id == e.id and
              b.status in ["pending", "approved"] and
              b.usage_at < ^return_at and
              b.return_at > ^usage_at,
            group_by: e.id,
            having:
              e.total_quantity - coalesce(sum(b.requested_quantity), 0) > 0,
            select_merge: %{
              available_quantity: e.total_quantity - coalesce(sum(b.requested_quantity), 0)
            }
        else
          from e in base_query,
            select_merge: %{available_quantity: e.total_quantity}
        end

      # FIX: wrap in subquery before counting
      total =
        final_query
        |> subquery()
        |> Repo.aggregate(:count, :id)

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

    def cancel_equipment_booking(%EquipmentBooking{} = booking, %Spato.Accounts.User{} = user, reason \\ nil) do
      case booking.status do
        "pending" ->
          update_equipment_booking(booking, %{
            status: "cancelled",
            cancelled_by_user_id: user.id,
            rejection_reason: reason
          })

        "approved" ->
          update_equipment_booking(booking, %{
            status: "cancelled",
            cancelled_by_user_id: user.id,
            rejection_reason: reason
          })

        _ -> {:error, :not_allowed}
      end
    end

    def update_equipment_booking(%EquipmentBooking{} = eb, attrs), do: eb |> EquipmentBooking.changeset(attrs) |> Repo.update()
    def delete_equipment_booking(%EquipmentBooking{} = eb), do: Repo.delete(eb)
    def change_equipment_booking(%EquipmentBooking{} = eb, attrs \\ %{}), do: EquipmentBooking.changeset(eb, attrs)

    def approve_equipment_booking(%EquipmentBooking{} = booking) do
      update_equipment_booking(booking, %{status: "approved"})
    end

    def reject_equipment_booking(%EquipmentBooking{} = booking, reason \\ nil) do
      alias Spato.Assets.Equipment

      Ecto.Multi.new()
      |> Ecto.Multi.update(:booking,
           EquipmentBooking.changeset(booking, %{status: "rejected", rejection_reason: reason})
         )
      |> Ecto.Multi.run(:restore_equipment, fn repo, %{booking: booking} ->
        equipment = repo.get!(Equipment, booking.equipment_id)
        new_qty = equipment.total_quantity + booking.requested_quantity
        equipment
        |> Ecto.Changeset.change(%{total_quantity: new_qty})
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
      base_query =
        from eb in EquipmentBooking,
          where: eb.user_id == ^user_id

      %{
        total: Repo.aggregate(base_query, :count, :id),
        pending: Repo.aggregate(from(eb in base_query, where: eb.status == "pending"), :count, :id),
        approved: Repo.aggregate(from(eb in base_query, where: eb.status == "approved"), :count, :id),
        completed: Repo.aggregate(from(eb in base_query, where: eb.status == "completed"), :count, :id)
      }
    end

    # == LIST APPROVED BOOKINGS IN RANGE ==
      def list_approved_bookings_in_range(start_date, end_date) do
        import Ecto.Query

        # Vehicles
        vehicle_query =
          from v in Spato.Bookings.VehicleBooking,
            where: v.status == "approved" and v.pickup_time >= ^start_date and v.return_time <= ^end_date,
            join: veh in assoc(v, :vehicle),
            select: %{
              id: v.id,
              type: "vehicle",
              title: veh.name,
              usage_at: v.pickup_time,
              return_at: v.return_time
            }

        # Equipments
        equipment_query =
          from e in Spato.Bookings.EquipmentBooking,
            where: e.status == "approved" and e.usage_at >= ^start_date and e.return_at <= ^end_date,
            join: eq in assoc(e, :equipment),
            select: %{
              id: e.id,
              type: "equipment",
              title: eq.name,
              usage_at: e.usage_at,
              return_at: e.return_at
            }

        # Merge both
        Repo.all(union_all(vehicle_query, ^equipment_query))
      end

  def get_user_catering_booking_stats(user_id) do
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
      from cb in CateringBooking,
        where: cb.user_id == ^user_id and cb.inserted_at >= ^beginning_of_week_dt and cb.inserted_at <= ^end_of_week_dt

    %{
      total: Repo.aggregate(base_query, :count, :id),
      pending: Repo.aggregate(from(cb in base_query, where: cb.status == "pending"), :count, :id),
      approved: Repo.aggregate(from(cb in base_query, where: cb.status == "approved"), :count, :id),
      rejected: Repo.aggregate(from(cb in base_query, where: cb.status == "rejected"), :count, :id),
      completed: Repo.aggregate(from(cb in base_query, where: cb.status == "completed"), :count, :id)
    }
  end

  def decimal_from_any(val) do
    cond do
      is_nil(val) -> Decimal.new("0.00")
      is_integer(val) -> Decimal.new(val)
      is_float(val) -> Decimal.from_float(val)
      is_binary(val) ->
        case Decimal.parse(val) do
          {d, _rest} -> d
          :error -> Decimal.new("0.00")
        end
      match?(%Decimal{}, val) -> val
      true -> Decimal.new("0.00")
    end
  end

  def format_money(nil), do: "RM 0.00"
  def format_money(%Decimal{} = dec),
  do: "RM #{:erlang.float_to_binary(Decimal.to_float(dec), [decimals: 2])}"


  alias Spato.Bookings.MeetingRoomBooking


  def list_meeting_room_bookings_paginated(params \\ %{}, user \\ nil) do
    page   = Map.get(params, "page", 1) |> to_int()
    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")
    date   = Map.get(params, "date", "")
    per_page = @per_page
    offset = (page - 1) * per_page

    base_query =
      from b in MeetingRoomBooking,
        order_by: [desc: b.inserted_at]

    scoped_query =
      case user do
        nil -> base_query
        _ -> from b in base_query, where: b.user_id == ^user.id
      end

    status_query =
      if status != "all" do
        from b in scoped_query, where: b.status == ^status
      else
        scoped_query
      end

    date_query =
      if date != "" do
        case Date.from_iso8601(date) do
          {:ok, parsed} ->
            from b in status_query,
              where:
                fragment("date(?)", b.start_time) == ^parsed or
                fragment("date(?)", b.end_time) == ^parsed
          _ -> status_query
        end
      else
        status_query
      end

    final_query =
      if search != "" do
        like_search = "%#{search}%"
        from b in date_query,
          left_join: u in assoc(b, :user),
          left_join: up in assoc(u, :user_profile),
          left_join: d in assoc(up, :department),
          left_join: mr in assoc(b, :meeting_room),
          where:
            ilike(b.purpose, ^like_search) or
            ilike(u.email, ^like_search) or
            ilike(up.full_name, ^like_search) or
            ilike(d.name, ^like_search) or
            ilike(mr.name, ^like_search) or
            ilike(mr.location, ^like_search),
          distinct: b.id,
          select: b
      else
        date_query
      end

    total =
      final_query
      |> exclude(:order_by)
      |> Repo.aggregate(:count, :id)

    bookings_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload([:meeting_room, user: [user_profile: [:department]]])
    total_pages = ceil(total / per_page)

    %{
      meeting_room_bookings_page: bookings_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  # --- Available Rooms ---
  def available_rooms(filters) do
    import Ecto.Query
    alias Spato.Repo
    alias Spato.Assets.MeetingRoom
    alias Spato.Bookings.MeetingRoomBooking

    query    = filters["query"]
    capacity = filters["capacity"]
    page     = Map.get(filters, "page", 1) |> to_int()
    per_page = 12
    offset   = (page - 1) * per_page

    # Parse filter times
    start_time = parse_datetime(filters["start_time"])
    end_time   = parse_datetime(filters["end_time"])

    # Base query – only rooms with status "tersedia"
    base_query =
      from r in MeetingRoom,
        preload: [:meeting_room_bookings],
        where: r.status == "tersedia"

    # Capacity filter
    base_query =
      if capacity not in [nil, ""] do
        case Integer.parse(capacity) do
          {cap, _} -> from r in base_query, where: r.capacity >= ^cap
          :error -> base_query
        end
      else
        base_query
      end

    # Search filter
    base_query =
      if query not in [nil, ""] do
        like_q = "%#{query}%"
        from r in base_query,
          where: ilike(r.name, ^like_q) or ilike(r.location, ^like_q)
      else
        base_query
      end

    # Availability filter – exclude rooms with conflicting bookings
    final_query =
      if start_time && end_time do
        from r in base_query,
          as: :room,
          where: not exists(
            from b in MeetingRoomBooking,
              where:
                b.meeting_room_id == parent_as(:room).id and
                b.status in ["pending", "approved"] and
                b.start_time < ^end_time and
                b.end_time > ^start_time
          )
      else
        base_query
      end

    # Total count for pagination
    total = final_query |> exclude(:order_by) |> Repo.aggregate(:count, :id)
    total_pages = ceil(total / per_page)

    # Paginated results
    rooms_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    %{
      meeting_rooms_page: rooms_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  def get_meeting_room_booking!(id) do
    Repo.get!(MeetingRoomBooking, id)
    |> Repo.preload([
      :meeting_room,
      [user: [user_profile: [:department]]],
      :approved_by_user,
      :cancelled_by_user
    ])
  end

  def create_meeting_room_booking(attrs \\ %{}) do
    %MeetingRoomBooking{}
    |> MeetingRoomBooking.changeset(attrs)
    |> Repo.insert()
  end

  def update_meeting_room_booking(%MeetingRoomBooking{} = meeting_room_booking, attrs) do
    meeting_room_booking
    |> MeetingRoomBooking.changeset(attrs)
    |> Repo.update()
  end

  def delete_meeting_room_booking(%MeetingRoomBooking{} = meeting_room_booking) do
    Repo.delete(meeting_room_booking)
  end

  def change_meeting_room_booking(%MeetingRoomBooking{} = meeting_room_booking, attrs \\ %{}) do
    MeetingRoomBooking.changeset(meeting_room_booking, attrs)
  end

  def approve_meeting_room_booking(%MeetingRoomBooking{} = vb),
    do: update_meeting_room_booking(vb, %{status: "approved"})

  def reject_meeting_room_booking(%MeetingRoomBooking{} = vb),
    do: update_meeting_room_booking(vb, %{status: "rejected"})

  def cancel_meeting_room_booking(%MeetingRoomBooking{} = vb, %Spato.Accounts.User{} = user) do
    case vb.status do
      "pending" ->
        update_meeting_room_booking(vb, %{status: "cancelled", cancelled_by_user_id: user.id})

      _ ->
        {:error, :not_allowed}
    end
  end

   import Ecto.Query

   def get_meeting_room_booking_stats do
    now = DateTime.utc_now()

    total =
      Repo.aggregate(MeetingRoomBooking, :count, :id)

    pending =
      Repo.aggregate(
        from(b in MeetingRoomBooking, where: b.status == "pending"),
        :count,
        :id
      )

    approved =
      Repo.aggregate(
        from(b in MeetingRoomBooking, where: b.status == "approved"),
        :count,
        :id
      )

    # Active = approved dan masa sekarang berada antara start_time dan end_time
    active =
      Repo.aggregate(
        from(b in MeetingRoomBooking,
          where:
            b.status == "approved" and
              b.start_time <= ^now and
              b.end_time >= ^now
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

  def get_user_meeting_room_booking_stats(user_id) do
    now = DateTime.utc_now()

    base_query =
      from b in MeetingRoomBooking,
        where: b.user_id == ^user_id

    total =
      Repo.aggregate(base_query, :count, :id)

    pending =
      Repo.aggregate(
        from(b in base_query, where: b.status == "pending"),
        :count,
        :id
      )

    approved =
      Repo.aggregate(
        from(b in base_query, where: b.status == "approved"),
        :count,
        :id
      )

    # Completed = approved and end_time has passed
    completed =
      Repo.aggregate(
        from(b in base_query,
          where: b.status == "approved" and b.end_time <= ^now
        ),
        :count,
        :id
      )

    %{
      total: total,
      pending: pending,
      approved: approved,
      completed: completed
    }
  end

   # Shared validator for all bookings
   def validate_datetime_order(changeset, start_field, end_field) do
    start_dt = Ecto.Changeset.get_field(changeset, start_field)
    end_dt   = Ecto.Changeset.get_field(changeset, end_field)

    cond do
      is_nil(start_dt) or is_nil(end_dt) ->
        changeset

      # Same exact datetime
      DateTime.compare(start_dt, end_dt) == :eq ->
        Ecto.Changeset.add_error(
          changeset,
          end_field,
          "Tarikh dan masa guna tidak boleh sama dengan tarikh dan masa pulang"
        )

      # End is before start
      DateTime.compare(start_dt, end_dt) == :gt ->
        Ecto.Changeset.add_error(
          changeset,
          end_field,
          "Tarikh pulang mesti selepas tarikh guna"
        )

      true ->
        changeset
    end
  end

  def valid_datetime_range?(pickup_time, return_time) when is_binary(pickup_time) and is_binary(return_time) do
    with {:ok, pickup, _} <- DateTime.from_iso8601(pickup_time),
         {:ok, return, _} <- DateTime.from_iso8601(return_time) do
      DateTime.compare(pickup, return) == :lt
    else
      _ -> false
    end
  end

  def valid_datetime_range?(_, _), do: false

end

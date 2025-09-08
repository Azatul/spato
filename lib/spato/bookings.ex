defmodule Spato.Bookings do
  @moduledoc """
  The Bookings context.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo

  alias Spato.Bookings.VehicleBooking

  @doc """
  Returns the list of vehicle_bookings.

  ## Examples

      iex> list_vehicle_bookings()
      [%VehicleBooking{}, ...]

  """
  def list_vehicle_bookings do
    Repo.all(VehicleBooking)
    |> Repo.preload([:user, :vehicle, :approved_by_user, :cancelled_by_user])
  end

  def list_vehicle_bookings_for_user(user_id) do
    from(vb in VehicleBooking, where: vb.user_id == ^user_id)
    |> Repo.all()
    |> Repo.preload([:user, :vehicle, :approved_by_user, :cancelled_by_user])
  end

  @doc """
  Returns paginated vehicle bookings with search and filtering.

  ## Examples

      iex> list_vehicle_bookings_paginated(%{"page" => "1", "search" => "car", "status" => "approved"})
      %{vehicle_bookings_page: [%VehicleBooking{}], total: 1, total_pages: 1, page: 1}

  """
  def list_vehicle_bookings_paginated(params) do
    page = case Map.get(params, "page", "1") do
      page when is_integer(page) -> page
      page when is_binary(page) -> String.to_integer(page)
      _ -> 1
    end

    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")
    booking_date = Map.get(params, "booking_date", "")
    per_page = 10
    offset = (page - 1) * per_page

    # Base query
    base_query = from(vb in VehicleBooking)

    # Apply search filter
    base_query = if search != "" do
      search_term = "%#{search}%"
      from(vb in base_query,
        join: v in assoc(vb, :vehicle),
        join: u in assoc(vb, :user),
        where: ilike(v.name, ^search_term) or
               ilike(v.plate_number, ^search_term) or
               ilike(vb.purpose, ^search_term) or
               ilike(vb.trip_destination, ^search_term) or
               ilike(u.email, ^search_term)
      )
    else
      base_query
    end

    # Apply status filter
    base_query = if status != "all" do
      from(vb in base_query, where: vb.status == ^status)
    else
      base_query
    end

    # Apply date filter
    base_query = if booking_date != "" do
      case Date.from_iso8601(booking_date) do
        {:ok, date} ->
          start_of_day = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
          end_of_day = DateTime.new!(date, ~T[23:59:59], "Etc/UTC")
          from(vb in base_query,
            where: vb.pickup_time >= ^start_of_day and vb.pickup_time <= ^end_of_day)
        _ -> base_query
      end
    else
      base_query
    end

    # Order by most recent first
    base_query = from(vb in base_query, order_by: [desc: vb.inserted_at])

    # Total count
    total = base_query |> exclude(:order_by) |> Repo.aggregate(:count, :id)

    # Paginated results
    vehicle_bookings_page = base_query
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()
    |> Repo.preload([:user, :vehicle, :approved_by_user, :cancelled_by_user])

    # Total pages
    total_pages = if total == 0 do
      1
    else
      Float.ceil(total / per_page) |> trunc()
    end

    %{
      vehicle_bookings_page: vehicle_bookings_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  @doc """
  Returns paginated vehicle bookings for a specific user with search and filtering.

  ## Examples

      iex> list_vehicle_bookings_for_user_paginated(123, %{"page" => "1", "search" => "car", "status" => "approved"})
      %{vehicle_bookings_page: [%VehicleBooking{}], total: 1, total_pages: 1, page: 1}

  """
  def list_vehicle_bookings_for_user_paginated(user_id, params) do
    page = case Map.get(params, "page", "1") do
      page when is_integer(page) -> page
      page when is_binary(page) -> String.to_integer(page)
      _ -> 1
    end

    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")
    booking_date = Map.get(params, "booking_date", "")
    per_page = 10
    offset = (page - 1) * per_page

    # Base query for user's bookings
    base_query = from(vb in VehicleBooking, where: vb.user_id == ^user_id)

    # Apply search filter
    base_query = if search != "" do
      search_term = "%#{search}%"
      from(vb in base_query,
        join: v in assoc(vb, :vehicle),
        where: ilike(v.name, ^search_term) or
               ilike(v.plate_number, ^search_term) or
               ilike(vb.purpose, ^search_term) or
               ilike(vb.trip_destination, ^search_term)
      )
    else
      base_query
    end

    # Apply status filter
    base_query = if status != "all" do
      from(vb in base_query, where: vb.status == ^status)
    else
      base_query
    end

    # Apply date filter
    base_query = if booking_date != "" do
      case Date.from_iso8601(booking_date) do
        {:ok, date} ->
          start_of_day = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
          end_of_day = DateTime.new!(date, ~T[23:59:59], "Etc/UTC")
          from(vb in base_query,
            where: vb.pickup_time >= ^start_of_day and vb.pickup_time <= ^end_of_day)
        _ -> base_query
      end
    else
      base_query
    end

    # Order by most recent first
    base_query = from(vb in base_query, order_by: [desc: vb.inserted_at])

    # Total count
    total = base_query |> exclude(:order_by) |> Repo.aggregate(:count, :id)

    # Paginated results
    vehicle_bookings_page = base_query
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()
    |> Repo.preload([:user, :vehicle, :approved_by_user, :cancelled_by_user])

    # Total pages
    total_pages = if total == 0 do
      1
    else
      Float.ceil(total / per_page) |> trunc()
    end

    %{
      vehicle_bookings_page: vehicle_bookings_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  @doc """
  Gets a single vehicle_booking.

  Raises `Ecto.NoResultsError` if the Vehicle booking does not exist.

  ## Examples

      iex> get_vehicle_booking!(123)
      %VehicleBooking{}

      iex> get_vehicle_booking!(456)
      ** (Ecto.NoResultsError)

  """
  def get_vehicle_booking!(id), do: Repo.get!(VehicleBooking, id)

  @doc """
  Creates a vehicle_booking.

  ## Examples

      iex> create_vehicle_booking(%{field: value})
      {:ok, %VehicleBooking{}}

      iex> create_vehicle_booking(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_vehicle_booking(attrs \\ %{}) do
    %VehicleBooking{}
    |> VehicleBooking.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a vehicle_booking.

  ## Examples

      iex> update_vehicle_booking(vehicle_booking, %{field: new_value})
      {:ok, %VehicleBooking{}}

      iex> update_vehicle_booking(vehicle_booking, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_vehicle_booking(%VehicleBooking{} = vehicle_booking, attrs) do
    vehicle_booking
    |> VehicleBooking.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a vehicle_booking.

  ## Examples

      iex> delete_vehicle_booking(vehicle_booking)
      {:ok, %VehicleBooking{}}

      iex> delete_vehicle_booking(vehicle_booking)
      {:error, %Ecto.Changeset{}}

  """
  def delete_vehicle_booking(%VehicleBooking{} = vehicle_booking) do
    Repo.delete(vehicle_booking)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking vehicle_booking changes.

  ## Examples

      iex> change_vehicle_booking(vehicle_booking)
      %Ecto.Changeset{data: %VehicleBooking{}}

  """
  def change_vehicle_booking(%VehicleBooking{} = vehicle_booking, attrs \\ %{}) do
    VehicleBooking.changeset(vehicle_booking, attrs)
  end

  def available_vehicles_paginated(params \\ %{}) do
    page = case Map.get(params, "page", "1") do
      page when is_integer(page) -> page
      page when is_binary(page) -> String.to_integer(page)
      _ -> 1
    end
    query = Map.get(params, "query", "")
    type = Map.get(params, "type", "all")
    capacity = Map.get(params, "capacity", "")
    pickup_time_str = Map.get(params, "pickup_time")
    return_time_str = Map.get(params, "return_time")

    # Convert string dates to DateTime if provided
    pickup_time = if pickup_time_str && pickup_time_str != "" do
      # Handle datetime-local format (YYYY-MM-DDTHH:MM) by adding seconds
      formatted_time = if String.length(pickup_time_str) == 16 do
        pickup_time_str <> ":00"
      else
        pickup_time_str
      end

      case DateTime.from_iso8601(formatted_time) do
        {:ok, datetime, _} -> datetime
        _ -> nil
      end
    else
      nil
    end

    return_time = if return_time_str && return_time_str != "" do
      # Handle datetime-local format (YYYY-MM-DDTHH:MM) by adding seconds
      formatted_time = if String.length(return_time_str) == 16 do
        return_time_str <> ":00"
      else
        return_time_str
      end

      case DateTime.from_iso8601(formatted_time) do
        {:ok, datetime, _} -> datetime
        _ -> nil
      end
    else
      nil
    end

    per_page = 12
    offset = (page - 1) * per_page

    base_query =
      from v in Spato.Assets.Vehicle,
        where: v.status == "tersedia",
        order_by: [desc: v.inserted_at]

    # Type filter
    base_query =
      if type != "all" do
        from v in base_query, where: v.type == ^type
      else
        base_query
      end

    # Capacity filter
    base_query =
      if capacity != "" do
        {cap_int, _} = Integer.parse(capacity)
        from v in base_query, where: v.capacity >= ^cap_int
      else
        base_query
      end

    # Search filter
    base_query =
      if query != "" do
        like_search = "%#{query}%"
        from v in base_query,
          where: ilike(v.name, ^like_search) or ilike(v.plate_number, ^like_search)
      else
        base_query
      end

    # Availability filter (exclude vehicles already booked in selected time range)
    base_query =
      if pickup_time && return_time do
        from v in base_query,
          left_join: b in assoc(v, :vehicle_bookings),
          where:
            is_nil(b.id) or
            b.status != "accepted" or
            fragment(
              "NOT (tsrange(?, ?) && tsrange(?, ?))",
              b.pickup_time,
              b.return_time,
              ^pickup_time,
              ^return_time
            )
      else
        base_query
      end

    # Total count
    total =
      base_query
      |> exclude(:order_by)
      |> Repo.aggregate(:count, :id)

    # Paginated results
    vehicles_page =
      base_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    # Total pages (FIXED — use Float.ceil instead of Integer.ceil)
    total_pages =
      if total == 0 do
        1
      else
        Float.ceil(total / per_page) |> trunc()
      end

    %{
      vehicles_page: vehicles_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  def available_vehicles(params \\ %{}) do
    query = Map.get(params, "query", "")
    type = Map.get(params, "type", "all")
    capacity = Map.get(params, "capacity", "")
    pickup_time_str = Map.get(params, "pickup_time")
    return_time_str = Map.get(params, "return_time")

    # Convert string dates to DateTime if provided
    pickup_time = if pickup_time_str && pickup_time_str != "" do
      formatted_time = if String.length(pickup_time_str) == 16 do
        pickup_time_str <> ":00"
      else
        pickup_time_str
      end

      case DateTime.from_iso8601(formatted_time) do
        {:ok, datetime, _} -> datetime
        _ -> nil
      end
    else
      nil
    end

    return_time = if return_time_str && return_time_str != "" do
      formatted_time = if String.length(return_time_str) == 16 do
        return_time_str <> ":00"
      else
        return_time_str
      end

      case DateTime.from_iso8601(formatted_time) do
        {:ok, datetime, _} -> datetime
        _ -> nil
      end
    else
      nil
    end

    base_query =
      from v in Spato.Assets.Vehicle,
        where: v.status == "tersedia",
        order_by: [desc: v.inserted_at]

    # Type filter
    base_query =
      if type != "all" do
        from v in base_query, where: v.type == ^type
      else
        base_query
      end

    # Capacity filter
    base_query =
      if capacity != "" do
        {cap_int, _} = Integer.parse(capacity)
        from v in base_query, where: v.capacity >= ^cap_int
      else
        base_query
      end

    # Search filter
    base_query =
      if query != "" do
        like_search = "%#{query}%"
        from v in base_query,
          where: ilike(v.name, ^like_search) or ilike(v.plate_number, ^like_search)
      else
        base_query
      end

    # Availability filter (exclude vehicles already booked in selected time range)
    base_query =
      if pickup_time && return_time do
        from v in base_query,
          left_join: b in assoc(v, :vehicle_bookings),
          where:
            is_nil(b.id) or
            b.status != "accepted" or
            fragment(
              "NOT (tsrange(?, ?) && tsrange(?, ?))",
              b.pickup_time,
              b.return_time,
              ^pickup_time,
              ^return_time
            )
      else
        base_query
      end

    Repo.all(base_query)
  end

end

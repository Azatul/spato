defmodule Spato.Bookings do
  @moduledoc """
  The Bookings context.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo

  alias Spato.Bookings.VehicleBooking

  @per_page 10

  @doc """
  Returns the list of vehicle_bookings.

  ## Examples

      iex> list_vehicle_bookings()
      [%VehicleBooking{}, ...]

  """
  def list_vehicle_bookings do
    Repo.all(VehicleBooking)
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

  def approve_booking(%VehicleBooking{} = booking) do
    update_vehicle_booking(booking, %{status: "approved"})
  end

  def reject_booking(%VehicleBooking{} = booking) do
    update_vehicle_booking(booking, %{status: "rejected"})
  end

  def cancel_booking(%VehicleBooking{} = booking) do
    update_vehicle_booking(booking, %{status: "cancelled"})
  end

  def complete_booking(%VehicleBooking{} = booking) do
    update_vehicle_booking(booking, %{status: "completed"})
  end

  @doc """
  Lists vehicle bookings with optional filtering, search, and pagination.

  Params can include:
    - "page" => integer or string
    - "search" => string
    - "status" => string ("all" or any booking status)

  Returns a map with:
    - vehicle_bookings_page: list for the current page
    - total: total number of bookings matching filters
    - total_pages: total number of pages
    - page: current page
  """
  def list_vehicle_bookings_paginated(params \\ %{}) do
    page = Map.get(params, "page", 1) |> to_int()
    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")
    date = Map.get(params, "date", "")
    per_page = @per_page
    offset = (page - 1) * per_page

    base_query =
      from b in VehicleBooking,
        order_by: [desc: b.inserted_at]

    # Filter by status
    filtered_query =
      if status != "all" do
        from b in base_query, where: b.status == ^status
      else
        base_query
      end

    # Filter by date
    filtered_query =
      if date != "" do
        {:ok, dt} = Date.from_iso8601(date)
        from b in filtered_query,
          where:
            fragment("date(?) <= ? and date(?) >= ?", b.pickup_time, ^dt, b.return_time, ^dt)
      else
        filtered_query
      end

    # Filter by search
    final_query =
      if search != "" do
        like_search = "%#{search}%"

        from b in filtered_query,
          where:
            ilike(b.purpose, ^like_search) or
            ilike(b.trip_destination, ^like_search) or
            ilike(b.additional_notes, ^like_search) or
            fragment("?::text LIKE ?", b.pickup_time, ^like_search) or
            fragment("?::text LIKE ?", b.return_time, ^like_search),
          distinct: b.id,
          select: b
      else
        filtered_query
      end

    total =
      final_query
      |> exclude(:order_by)
      |> Repo.aggregate(:count, :id)

    vehicle_bookings_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    total_pages = ceil(total / per_page)

    %{
      vehicle_bookings_page: vehicle_bookings_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  # --- HELPERS ---
  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val), do: String.to_integer(val)
  defp to_int(_), do: 1

  def get_booking_stats(user_id \\ nil) do
    import Ecto.Query
    alias Spato.Bookings.VehicleBooking
    alias Spato.Repo

    now = DateTime.utc_now()
    beginning_of_week =
      Date.beginning_of_week(DateTime.to_date(now))
      |> DateTime.new!(~T[00:00:00], "Etc/UTC")

    end_of_week =
      Date.end_of_week(DateTime.to_date(now))
      |> DateTime.new!(~T[23:59:59], "Etc/UTC")

    base_query =
      if user_id do
        from b in VehicleBooking, where: b.user_id == ^user_id
      else
        from b in VehicleBooking
      end

    %{
      total_this_week:
        base_query
        |> where([b], b.pickup_time >= ^beginning_of_week and b.pickup_time <= ^end_of_week)
        |> Repo.aggregate(:count, :id),

      completed:
        base_query
        |> where([b], b.status == "completed")
        |> Repo.aggregate(:count, :id),

      pending:
        base_query
        |> where([b], b.status == "pending")
        |> Repo.aggregate(:count, :id),

      approved:
        base_query
        |> where([b], b.status == "approved")
        |> Repo.aggregate(:count, :id)
    }
  end

end

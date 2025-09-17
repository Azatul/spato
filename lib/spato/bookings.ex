defmodule Spato.Bookings do
  @moduledoc """
  The Bookings context.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo
  alias Spato.Assets.MeetingRoom
  alias Spato.Bookings.MeetingRoomBooking

  @per_page 10

  @doc """
  Returns the list of meeting_room_bookings.

  ## Examples

      iex> list_meeting_room_bookings()
      [%MeetingRoomBooking{}, ...]

  """
  def list_meeting_room_bookings do
    Repo.all(MeetingRoomBooking)
    |> Repo.preload([:room, :user])
  end


  @doc """
  Gets a single meeting_room_booking.

  Raises `Ecto.NoResultsError` if the Meeting room booking does not exist.

  ## Examples

      iex> get_meeting_room_booking!(123)
      %MeetingRoomBooking{}

      iex> get_meeting_room_booking!(456)
      ** (Ecto.NoResultsError)

  """
  def get_meeting_room_booking!(id), do: Repo.get!(MeetingRoomBooking, id)

  @doc """
  Creates a meeting_room_booking.

  ## Examples

      iex> create_meeting_room_booking(%{field: value})
      {:ok, %MeetingRoomBooking{}}

      iex> create_meeting_room_booking(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_meeting_room_booking(attrs \\ %{}) do
    %MeetingRoomBooking{}
    |> MeetingRoomBooking.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a meeting_room_booking.

  ## Examples

      iex> update_meeting_room_booking(meeting_room_booking, %{field: new_value})
      {:ok, %MeetingRoomBooking{}}

      iex> update_meeting_room_booking(meeting_room_booking, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_meeting_room_booking(%MeetingRoomBooking{} = meeting_room_booking, attrs) do
    meeting_room_booking
    |> MeetingRoomBooking.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a meeting_room_booking.

  ## Examples

      iex> delete_meeting_room_booking(meeting_room_booking)
      {:ok, %MeetingRoomBooking{}}

      iex> delete_meeting_room_booking(meeting_room_booking)
      {:error, %Ecto.Changeset{}}

  """
  def delete_meeting_room_booking(%MeetingRoomBooking{} = meeting_room_booking) do
    Repo.delete(meeting_room_booking)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking meeting_room_booking changes.

  ## Examples

      iex> change_meeting_room_booking(meeting_room_booking)
      %Ecto.Changeset{data: %MeetingRoomBooking{}}

  """
  def change_meeting_room_booking(%MeetingRoomBooking{} = meeting_room_booking, attrs \\ %{}) do
    MeetingRoomBooking.changeset(meeting_room_booking, attrs)
  end
  def list_meeting_room_bookings_by_user(user_id) do
    from(b in MeetingRoomBooking,
      where: b.user_id == ^user_id,
      order_by: [desc: b.inserted_at]
    )
    |> Repo.all()
  end
  def list_available_meeting_rooms(start_time, end_time, participants) do
    import Ecto.Query

    booked_rooms_ids =
      from(b in MeetingRoomBooking,
        where: fragment("? < ? AND ? > ?", b.start_time, ^end_time, b.end_time, ^start_time),
        select: b.meeting_room_id
      )
      |> Repo.all()

    from(r in Spato.Assets.MeetingRoom,
      where: r.capacity >= ^participants and r.id not in ^booked_rooms_ids
    )
    |> Repo.all()
  end


  def booking_summary_user(user_id) do
    now = Date.utc_today()

    total =
      from(b in MeetingRoomBooking, where: b.user_id == ^user_id)
      |> Repo.aggregate(:count, :id)

    pending =
      from(b in MeetingRoomBooking,
        where: b.user_id == ^user_id and b.status == "pending"
      )
      |> Repo.aggregate(:count, :id)

    this_month =
      from(b in MeetingRoomBooking,
        where: b.user_id == ^user_id and
               fragment("date_part('month', ?)", b.inserted_at) == ^now.month and
               fragment("date_part('year', ?)", b.inserted_at) == ^now.year
      )
      |> Repo.aggregate(:count, :id)

    %{
      total: total,
      pending: pending,
      this_month: this_month
    }
  end

  def booking_summary do
    now = Date.utc_today()

    total =
      Repo.aggregate(MeetingRoomBooking, :count, :id)

    pending =
      from(b in MeetingRoomBooking, where: b.status == "pending")
      |> Repo.aggregate(:count, :id)

    this_month =
      from(b in MeetingRoomBooking,
        where:
          fragment("date_part('month', ?)", b.inserted_at) == ^now.month and
          fragment("date_part('year', ?)", b.inserted_at) == ^now.year
      )
      |> Repo.aggregate(:count, :id)

    %{
      total: total,
      pending: pending,
      this_month: this_month
    }
  end

  def list_meeting_room_bookings_filtered do
    from(b in MeetingRoomBooking,
      where: b.status in ["diterima", "dalam proses", "ditolak"],
      order_by: [desc: b.inserted_at]
    )
    |> Repo.all()
  end

  # --- FILTER, SEARCH & PAGINATION FOR MEETING ROOM BOOKINGS ---
  def list_meeting_room_bookings_paginated(params \\ %{}) do
    page = Map.get(params, "page", 1) |> to_int()
    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")
    per_page = @per_page
    offset = (page - 1) * per_page

    base_query =
      from b in MeetingRoomBooking,
        order_by: [desc: b.inserted_at]

    filtered_query =
      if status != "all" do
        from b in base_query, where: b.status == ^status
      else
        base_query
      end

    final_query =
      if search != "" do
        like_search = "%#{search}%"

        from b in filtered_query,
          where:
            ilike(b.purpose, ^like_search) or
            ilike(b.notes, ^like_search) or
            ilike(b.recurrence_pattern, ^like_search) or
            fragment("?::text LIKE ?", b.participants, ^like_search),
          select: b
      else
        filtered_query
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

    total_pages = ceil_div(total, per_page)

    %{
      bookings_page: bookings_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  def approve_meeting_room_booking(%MeetingRoomBooking{} = booking) do
    booking
    |> Ecto.Changeset.change(status: "approved")
    |> Repo.update()
  end

  def reject_meeting_room_booking(%MeetingRoomBooking{} = booking) do
    booking
    |> Ecto.Changeset.change(status: "rejected")
    |> Repo.update()
  end

  def list_available_meeting_rooms(opts \\ %{}) do
    import Ecto.Query
    alias Spato.Repo

    query = from r in MeetingRoom,
      where: r.status == "tersedia",
      order_by: [asc: r.name]

    # Apply capacity filter
    query = if opts[:capacity], do: from(r in query, where: r.capacity >= ^opts[:capacity]), else: query

    # Apply search filter
    query = if opts[:search], do: from(r in query, where: ilike(r.name, ^"%#{opts[:search]}%")), else: query

    Repo.all(query)
  end


  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val), do: String.to_integer(val)
  defp to_int(_), do: 1

  defp ceil_div(a, b) when b > 0 do
    div(a + b - 1, b)
  end
end

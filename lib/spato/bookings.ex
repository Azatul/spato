defmodule Spato.Bookings do
  @moduledoc """
  The Bookings context.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo

  alias Spato.Bookings.MeetingRoomBooking

  @doc """
  Returns the list of meeting_room_bookings.

  ## Examples

      iex> list_meeting_room_bookings()
      [%MeetingRoomBooking{}, ...]

  """
  def list_meeting_room_bookings do
    Repo.all(MeetingRoomBooking)
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
    from(b in MeetingRoomBooking, where: b.user_id == ^user_id, order_by: [desc: b.inserted_at])
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



end

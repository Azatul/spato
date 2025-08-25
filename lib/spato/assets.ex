defmodule Spato.Assets do
  @moduledoc """
  The Assets context.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo

  alias Spato.Assets.MeetingRoom

  @doc """
  Returns the list of meeting_rooms.

  ## Examples

      iex> list_meeting_rooms()
      [%MeetingRoom{}, ...]

  """
  def list_meeting_rooms do
    Repo.all(MeetingRoom)
  end

  @doc """
  Gets a single meeting_room.

  Raises `Ecto.NoResultsError` if the Meeting room does not exist.

  ## Examples

      iex> get_meeting_room!(123)
      %MeetingRoom{}

      iex> get_meeting_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_meeting_room!(id), do: Repo.get!(MeetingRoom, id)

  @doc """
  Creates a meeting_room.

  ## Examples

      iex> create_meeting_room(%{field: value})
      {:ok, %MeetingRoom{}}

      iex> create_meeting_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_meeting_room(attrs \\ %{}) do
    %MeetingRoom{}
    |> MeetingRoom.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a meeting_room.

  ## Examples

      iex> update_meeting_room(meeting_room, %{field: new_value})
      {:ok, %MeetingRoom{}}

      iex> update_meeting_room(meeting_room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_meeting_room(%MeetingRoom{} = meeting_room, attrs) do
    meeting_room
    |> MeetingRoom.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a meeting_room.

  ## Examples

      iex> delete_meeting_room(meeting_room)
      {:ok, %MeetingRoom{}}

      iex> delete_meeting_room(meeting_room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_meeting_room(%MeetingRoom{} = meeting_room) do
    Repo.delete(meeting_room)
  end

  def list_meeting_rooms_filtered(status, keyword) do
    query =
      from r in MeetingRoom,
        order_by: [asc: r.name]

    query =
      if status in ["available", "maintenance"] do
        db_status = if status == "available", do: "Tersedia", else: "Dalam Penyelenggaraan"
        from r in query, where: r.status == ^db_status
      else
        query
      end

    query =
      if keyword != "" do
        from r in query, where: ilike(r.name, ^"%#{keyword}%")
      else
        query
      end

    Repo.all(query)
  end


  @doc """
  Returns an `%Ecto.Changeset{}` for tracking meeting_room changes.

  ## Examples

      iex> change_meeting_room(meeting_room)
      %Ecto.Changeset{data: %MeetingRoom{}}

  """
  def change_meeting_room(%MeetingRoom{} = meeting_room, attrs \\ %{}) do
    MeetingRoom.changeset(meeting_room, attrs)
  end
end

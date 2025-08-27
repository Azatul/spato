defmodule Spato.Assets do
  import Ecto.Query, warn: false
  alias Spato.Repo
  alias Spato.Assets.MeetingRoom

  @page_size 10

  # List rooms with filter, search, pagination
  def list_meeting_rooms_filtered(status \\ "", keyword \\ "", page \\ 1, page_size \\ @page_size) do
    MeetingRoom
    |> filter_by_status(status)
    |> search_by_keyword(keyword)
    |> order_by([m], desc: m.updated_at)
    |> limit(^page_size)
    |> offset(^((page - 1) * page_size))
    |> Repo.all()
  end

  # Count total rooms matching filter & search (for pagination)
  def count_meeting_rooms_filtered(status \\ "", keyword \\ "") do
    MeetingRoom
    |> filter_by_status(status)
    |> search_by_keyword(keyword)
    |> Repo.aggregate(:count, :id)
  end

  # --- Helper Functions ---

  # Status filter
  defp filter_by_status(query, ""), do: query
  defp filter_by_status(query, "available"), do: where(query, [m], m.status == "Tersedia")
  defp filter_by_status(query, "maintenance"), do: where(query, [m], m.status == "Dalam Penyelenggaraan")
  defp filter_by_status(query, _other), do: query

  # Keyword search
  defp search_by_keyword(query, ""), do: query
  defp search_by_keyword(query, keyword) do
    pattern = "%#{keyword}%"
    where(query, [m], ilike(m.name, ^pattern) or ilike(m.location, ^pattern))
  end

  # --- Existing CRUD functions ---

  def change_meeting_room(%MeetingRoom{} = meeting_room, attrs \\ %{}) do
    MeetingRoom.changeset(meeting_room, attrs)
  end


  def create_meeting_room(attrs \\ %{}) do
    %MeetingRoom{}
    |> MeetingRoom.changeset(attrs)
    |> Repo.insert()
  end


  def get_meeting_room!(id), do: Repo.get!(MeetingRoom, id)

  def update_meeting_room(%MeetingRoom{} = room, attrs) do
    room
    |> MeetingRoom.changeset(attrs)
    |> Repo.update()
  end
end

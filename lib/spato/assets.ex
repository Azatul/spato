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

  @moduledoc """
  The Assets context.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo
  alias Spato.Assets.Vehicle

  @per_page 10

  # --- CRUD FUNCTIONS ---

  def list_vehicles do
    Repo.all(Vehicle)
    |> Repo.preload([user: :user_profile, created_by: :user_profile])
  end

  def get_vehicle!(id) do
    Repo.get!(Vehicle, id)
    |> Repo.preload([user: :user_profile, created_by: :user_profile])
  end

  def create_vehicle(attrs \\ %{}, admin_id) do
    %Vehicle{}
    |> Vehicle.changeset(attrs)
    |> Ecto.Changeset.put_change(:created_by_id, admin_id)
    |> Repo.insert()
  end

  def update_vehicle(%Vehicle{} = vehicle, attrs) do
    vehicle
    |> Vehicle.changeset(attrs)
    |> Repo.update()
  end

  def delete_vehicle(%Vehicle{} = vehicle), do: Repo.delete(vehicle)

  def change_vehicle(%Vehicle{} = vehicle, attrs \\ %{}), do: Vehicle.changeset(vehicle, attrs)

  # --- FILTER, SEARCH & PAGINATION ---

  @doc """
  Lists vehicles with optional filtering, search, and pagination.

  Params can include:
    - "page" => integer or string
    - "search" => string
    - "status" => string ("all", "tersedia", "dalam_penyelenggaraan")

  Returns a map with:
    - vehicles_page: list of vehicles for the current page
    - total: total number of vehicles matching filters
    - total_pages: total number of pages
    - page: current page
  """
  def list_vehicles_paginated(params \\ %{}) do
    page = Map.get(params, "page", 1) |> to_int()
    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")
    per_page = @per_page
    offset = (page - 1) * per_page

    # Base query
    base_query =
      from v in Vehicle,
        order_by: [desc: v.inserted_at]

    # Status filter
    filtered_query =
      if status != "all" do
        from v in base_query, where: v.status == ^status
      else
        base_query
      end

    # Search filter — use proper joins!
    final_query =
      if search != "" do
        like_search = "%#{search}%"

        from v in filtered_query,
          left_join: u in assoc(v, :user),
          left_join: up in assoc(u, :user_profile),
          where:
            ilike(v.name, ^like_search) or
            ilike(v.type, ^like_search) or
            ilike(v.plate_number, ^like_search) or
            fragment("?::text LIKE ?", v.capacity, ^like_search),
            distinct: v.id,
          select: v
      else
        filtered_query
      end

    # Total count
    total =
      final_query
      |> exclude(:order_by)
      |> Repo.aggregate(:count, :id)

    # Paginated results, preloading associations correctly
    vehicles_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload([user: :user_profile, created_by: :user_profile])

    total_pages = ceil(total / per_page)

    %{
      vehicles_page: vehicles_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  # --- HELPERS ---
  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val), do: String.to_integer(val)
  defp to_int(_), do: 1
end

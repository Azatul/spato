defmodule Spato.Assets do
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

  # --- EQUIPMENTS ---
  alias Spato.Assets.Equipment

  def list_equipments do
    Repo.all(Equipment)
    |> Repo.preload([user: :user_profile, created_by: :user_profile])
  end

  def get_equipment!(id) do
    Repo.get!(Equipment, id)
    |> Repo.preload([user: :user_profile, created_by: :user_profile])
  end

  def create_equipment(attrs \\ %{}, admin_id) do
    %Equipment{}
    |> Equipment.changeset(attrs)
    |> Ecto.Changeset.put_change(:created_by_id, admin_id)
    |> Repo.insert()
  end

  def update_equipment(%Equipment{} = equipment, attrs) do
    equipment
    |> Equipment.changeset(attrs)
    |> Repo.update()
  end

  def delete_equipment(%Equipment{} = equipment), do: Repo.delete(equipment)

  def change_equipment(%Equipment{} = equipment, attrs \\ %{}), do: Equipment.changeset(equipment, attrs)

  def list_equipments_paginated(params \\ %{}) do
    page = Map.get(params, "page", 1) |> to_int()
    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")
    per_page = @per_page
    offset = (page - 1) * per_page

    # Base query
    base_query =
      from v in Equipment,
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
            ilike(v.serial_number, ^like_search) or
            fragment("?::text LIKE ?", v.total_quantity, ^like_search),
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
    equipments_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload([user: :user_profile, created_by: :user_profile])

    total_pages = ceil(total / per_page)

    %{
      equipments_page: equipments_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  alias Spato.Assets.MeetingRoom

   # --- CRUD FUNCTIONS ---

  def list_meeting_rooms do
    Repo.all(MeetingRoom)
    |> Repo.preload([user: :user_profile, created_by: :user_profile])
  end

  def get_meeting_room!(id) do
    Repo.get!(MeetingRoom, id)
    |> Repo.preload([user: :user_profile, created_by: :user_profile])
  end

  def create_meeting_room(attrs \\ %{}, admin_id) do
    attrs_with_creator = Map.put(attrs, "created_by_id", admin_id)

    %MeetingRoom{}
    |> MeetingRoom.changeset(attrs_with_creator)
    |> Repo.insert()
  end

  def update_meeting_room(%MeetingRoom{} = meeting_room, attrs) do
    meeting_room
    |> MeetingRoom.changeset(attrs)
    |> Repo.update()
  end

  def delete_meeting_room(%MeetingRoom{} = meeting_room), do: Repo.delete(meeting_room)

  def change_meeting_room(%MeetingRoom{} = meeting_room, attrs \\ %{}), do: MeetingRoom.changeset(meeting_room, attrs)

  def list_meeting_rooms_paginated(params \\ %{}) do
    page = Map.get(params, "page", 1) |> to_int()
    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")
    per_page = @per_page
    offset = (page - 1) * per_page

    # Base query
    base_query =
      from m in MeetingRoom,
        order_by: [desc: m.inserted_at]

    # Status filter
    filtered_query =
      if status != "all" do
        from m in base_query, where: m.status == ^status
      else
        base_query
      end

    # Search filter
    final_query =
      if search != "" do
        like_search = "%#{search}%"

        from m in filtered_query,
          left_join: u in assoc(m, :user),
          left_join: up in assoc(u, :user_profile),
          where:
            ilike(m.name, ^like_search) or
            ilike(m.location, ^like_search) or
            ilike(m.available_facility, ^like_search) or
            fragment("?::text LIKE ?", m.capacity, ^like_search),
          distinct: m.id,
          select: m
      else
        filtered_query
      end

    # Total count
    total =
      final_query
      |> exclude(:order_by)
      |> Repo.aggregate(:count, :id)

    # Paginated results with preload
    meeting_rooms_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload([user: :user_profile, created_by: :user_profile])

    total_pages = ceil(total / per_page)

    %{
      meeting_rooms_page: meeting_rooms_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  alias Spato.Assets.CateringMenu

  @doc """
  Returns the list of catering_menus.

  ## Examples

      iex> list_catering_menus()
      [%CateringMenu{}, ...]

  """
  def list_catering_menus do
    Repo.all(CateringMenu)
    |> Repo.preload([user: :user_profile, created_by: :user_profile])
  end

  @doc """
  Gets a single catering_menu.

  Raises `Ecto.NoResultsError` if the Catering menu does not exist.

  ## Examples

      iex> get_catering_menu!(123)
      %CateringMenu{}

      iex> get_catering_menu!(456)
      ** (Ecto.NoResultsError)

  """
  def get_catering_menu!(id) do
    Repo.get!(CateringMenu, id)
    |> Repo.preload([user: :user_profile, created_by: :user_profile])
  end

  @doc """
  Creates a catering_menu.

  ## Examples

      iex> create_catering_menu(%{field: value})
      {:ok, %CateringMenu{}}

      iex> create_catering_menu(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_catering_menu(attrs \\ %{}, admin_id) do
    %CateringMenu{}
    |> CateringMenu.changeset(attrs)
    |> Ecto.Changeset.put_change(:created_by_id, admin_id)
    |> Repo.insert()
  end

  @doc """
  Updates a catering_menu.

  ## Examples

      iex> update_catering_menu(catering_menu, %{field: new_value})
      {:ok, %CateringMenu{}}

      iex> update_catering_menu(catering_menu, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_catering_menu(%CateringMenu{} = catering_menu, attrs) do
    catering_menu
    |> CateringMenu.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a catering_menu.

  ## Examples

      iex> delete_catering_menu(catering_menu)
      {:ok, %CateringMenu{}}

      iex> delete_catering_menu(catering_menu)
      {:error, %Ecto.Changeset{}}

  """
  def delete_catering_menu(%CateringMenu{} = catering_menu) do
    Repo.delete(catering_menu)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking catering_menu changes.

  ## Examples

      iex> change_catering_menu(catering_menu)
      %Ecto.Changeset{data: %CateringMenu{}}

  """
  def change_catering_menu(%CateringMenu{} = catering_menu, attrs \\ %{}) do
    CateringMenu.changeset(catering_menu, attrs)
  end

  def list_catering_menus_paginated(params \\ %{}) do
    page = Map.get(params, "page", 1) |> to_int()
    search = Map.get(params, "search", "")
    type = Map.get(params, "type", "all")
    per_page = @per_page
    offset = (page - 1) * per_page

    base_query =
      from c in CateringMenu,
        order_by: [desc: c.inserted_at]

    filtered_query =
      if type != "all" do
        from c in base_query, where: c.type == ^type
      else
        base_query
      end

    final_query =
      if search != "" do
        like_search = "%#{search}%"

        from c in filtered_query,
          where:
            ilike(c.name, ^like_search) or
            ilike(c.description, ^like_search) or
            fragment("?::text LIKE ?", c.price_per_head, ^like_search),
          distinct: c.id,
          select: c
      else
        filtered_query
      end

    total =
      final_query
      |> exclude(:order_by)
      |> Repo.aggregate(:count, :id)

    catering_menus_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload([user: :user_profile, created_by: :user_profile])

    total_pages = ceil(total / per_page)

    %{
      catering_menus_page: catering_menus_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end
end

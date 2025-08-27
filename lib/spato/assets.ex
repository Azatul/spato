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
    |> Repo.preload(user: :user_profile)
  end

  def get_vehicle!(id) do
    Repo.get!(Vehicle, id)
    |> Repo.preload(user: :user_profile)
  end

  def create_vehicle(attrs \\ %{}, user_id) do
    %Vehicle{}
    |> Vehicle.changeset(attrs)
    |> Ecto.Changeset.put_change(:user_id, user_id)
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

    # Build base query
    base_query =
      from v in Vehicle,
        preload: [user: :user_profile],
        order_by: [desc: v.inserted_at]

    # Filter by status
    filtered_query =
      if status != "all" do
        from v in base_query, where: v.status == ^status
      else
        base_query
      end

    # Apply search with proper joins
    final_query =
      if search != "" do
        like_search = "%#{search}%"

        # We need to join with user and user_profile for the search condition
        from v in filtered_query,
          left_join: u in assoc(v, :user),
          left_join: up in assoc(u, :user_profile),
          where: ilike(v.name, ^like_search) or
                ilike(v.type, ^like_search) or
                ilike(v.plate_number, ^like_search) or
                ilike(up.full_name, ^like_search) or
                fragment("?::text LIKE ?", v.capacity, ^like_search)
      else
        filtered_query
      end

    # Get total count (for all matching records)
    total = Repo.aggregate(final_query, :count, :id)

    # Get paginated results with proper limit/offset
    vehicles_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

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

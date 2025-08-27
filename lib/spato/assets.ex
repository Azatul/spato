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

    query =
      from v in Vehicle,
        order_by: [desc: v.inserted_at]

    # Filter by status
    query =
      if status != "all" do
        from v in query, where: v.status == ^status
      else
        query
      end

    # Search by name, type, plate_number, or capacity
    query =
      if search != "" do
        like_search = "%#{search}%"
        from v in query,
          where: ilike(v.name, ^like_search) or
                 ilike(v.type, ^like_search) or
                 ilike(v.plate_number, ^like_search) or
                 fragment("?::text LIKE ?", v.capacity, ^like_search)
      else
        query
      end

    vehicles = Repo.all(query) |> Repo.preload(user: :user_profile)
    vehicles_page = paginate_list(vehicles, page)
    total_pages = total_pages(vehicles)

    %{
      vehicles_page: vehicles_page,
      total: length(vehicles),
      total_pages: total_pages,
      page: page
    }
  end

  # --- HELPERS ---
  defp paginate_list(list, page), do: list |> Enum.chunk_every(@per_page) |> Enum.at(page - 1, [])
  defp total_pages(list), do: (Enum.count(list) / @per_page) |> Float.ceil() |> trunc()
  defp to_int(val) when is_integer(val), do: val
  defp to_int(val) when is_binary(val), do: String.to_integer(val)
  defp to_int(_), do: 1
end

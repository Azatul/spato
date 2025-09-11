defmodule Spato.Bookings do
  @moduledoc """
  The Bookings context for managing vehicle bookings.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo
  alias Spato.Bookings.VehicleBooking

  @per_page 10

  # --- Listing ---

  def list_vehicle_bookings(user \\ nil) do
    VehicleBooking
    |> scope_by_user(user)
    |> order_by([vb], desc: vb.inserted_at)
    |> Repo.all()
  end

  def list_vehicle_bookings_paginated(params, user \\ nil) do
    page   = Map.get(params, "page", 1)
    search = Map.get(params, "search", "")
    status = Map.get(params, "status", "all")
    date   = Map.get(params, "date", "")

    query =
      VehicleBooking
      |> scope_by_user(user)
      |> filter_search(search)
      |> filter_status(status)
      |> filter_date(date)
      |> order_by([vb], desc: vb.inserted_at)

    total = Repo.aggregate(query, :count)
    total_pages = max(div(total + @per_page - 1, @per_page), 1)
    offset = (page - 1) * @per_page

    vehicle_bookings_page =
      query
      |> limit(^@per_page)
      |> offset(^offset)
      |> Repo.all()

    %{
      vehicle_bookings_page: vehicle_bookings_page,
      total_pages: total_pages,
      total: total,
      page: page
    }
  end



  # --- CRUD ---

  def get_vehicle_booking!(id), do: Repo.get!(VehicleBooking, id)

  def create_vehicle_booking(attrs) do
    %VehicleBooking{}
    |> VehicleBooking.changeset(attrs)
    |> Repo.insert()
  end

  def update_vehicle_booking(%VehicleBooking{} = vb, attrs) do
    vb
    |> VehicleBooking.changeset(attrs)
    |> Repo.update()
  end

  def delete_vehicle_booking(%VehicleBooking{} = vb), do: Repo.delete(vb)

  def change_vehicle_booking(%VehicleBooking{} = vb, attrs \\ %{}) do
    VehicleBooking.changeset(vb, attrs)
  end

  # --- Actions ---

  def approve_booking(%VehicleBooking{} = vb),
    do: update_vehicle_booking(vb, %{status: "approved"})

  def reject_booking(%VehicleBooking{} = vb),
    do: update_vehicle_booking(vb, %{status: "rejected"})

  # --- Private Helpers ---

  defp scope_by_user(query, nil), do: query
  defp scope_by_user(query, user),
    do: (from vb in query, where: vb.user_id == ^user.id)

  defp filter_search(query, ""), do: query
  defp filter_search(query, search) do
    from vb in query,
      where: ilike(vb.purpose, ^"%#{search}%") or ilike(vb.trip_destination, ^"%#{search}%")
  end

  defp filter_status(query, "all"), do: query
  defp filter_status(query, status),
    do: (from vb in query, where: vb.status == ^status)

  defp filter_date(query, ""), do: query
  defp filter_date(query, date) do
    case Date.from_iso8601(date) do
      {:ok, parsed} ->
        from vb in query,
          where:
            fragment("date(?)", vb.pickup_time) == ^parsed or
            fragment("date(?)", vb.return_time) == ^parsed

      _ ->
        query
    end
  end
end

defmodule Spato.Bookings do
  @moduledoc """
  The Bookings context.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo

  alias Spato.Bookings.VehicleBooking

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
end

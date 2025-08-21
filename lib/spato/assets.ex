defmodule Spato.Assets do
  @moduledoc """
  The Assets context.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo

  alias Spato.Assets.CateringMenu

  @doc """
  Returns the list of catering_menus.

  ## Examples

      iex> list_catering_menus()
      [%CateringMenu{}, ...]

  """
  def list_catering_menus do
    Repo.all(CateringMenu)
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
  def get_catering_menu!(id), do: Repo.get!(CateringMenu, id)

  @doc """
  Creates a catering_menu.

  ## Examples

      iex> create_catering_menu(%{field: value})
      {:ok, %CateringMenu{}}

      iex> create_catering_menu(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_catering_menu(attrs \\ %{}) do
    %CateringMenu{}
    |> CateringMenu.changeset(attrs)
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
end

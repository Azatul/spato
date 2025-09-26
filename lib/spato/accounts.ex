defmodule Spato.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Spato.Repo

  alias Spato.Accounts.{User, UserToken, UserNotifier, Department, UserProfile}

  @per_page 10
  ## ----------------------
  ## User functions
  ## ----------------------

  # Get all users
  def list_users, do: Repo.all(User)

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end


  # Get user by email
  def get_user_by_email(email) when is_binary(email), do: Repo.get_by(User, email: email)

  # Get user by email and password
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    case Repo.get_by(User, email: email) do
      nil -> nil
      user -> if User.valid_password?(user, password), do: user
    end
  end

  # Get single user
  def get_user!(id), do: Repo.get!(User, id)

  # Register user
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  # Change user registration (tracking changes)
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## ----------------------
  ## Email / Settings
  ## ----------------------

  def change_user_email(user, attrs \\ %{}), do: User.email_changeset(user, attrs, validate_email: false)

  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset =
      user
      |> User.email_changeset(%{email: email})
      |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, [context]))
  end

  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")
    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  ## ----------------------
  ## Password / Session
  ## ----------------------

  def change_user_password(user, attrs \\ %{}), do: User.password_changeset(user, attrs, hash_password: false)

  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    case Repo.one(query) do
      nil -> nil
      user -> Repo.preload(user, user_profile: [:department])
    end
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## ----------------------
  ## Confirmation / Reset
  ## ----------------------

  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query), do: user
  end

  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## ----------------------
  ## Department functions
  ## ----------------------

  def list_departments, do: Repo.all(Department)
  def get_department!(id), do: Repo.get!(Department, id)
  def create_department(attrs \\ %{}) do
    %Department{}
    |> Department.changeset(attrs)
    |> Repo.insert()
  end
  def update_department(%Department{} = department, attrs) do
    department
    |> Department.changeset(attrs)
    |> Repo.update()
  end
  def delete_department(%Department{} = department), do: Repo.delete(department)
  def change_department(%Department{} = department, attrs \\ %{}), do: Department.changeset(department, attrs)

  def count_departments do
    Repo.aggregate(Department, :count, :id)
  end

  def department_staff_counts do
    Repo.all(from d in Department,
      left_join: up in UserProfile, on: up.department_id == d.id,
      group_by: d.id,
      select: {d.id, count(up.id)})
    |> Enum.map(fn {id, count} -> {id, count || 0} end)
    |> Map.new()
  end

  @doc """
  Returns department statistics as a map for use in the stats cards:
    - total_departments: total number of departments
    - active_departments: number of departments that have at least one staff
    - inactive_departments: number of departments with no staff
    - total_staff: total number of staff across all departments
  """
  def department_stats do
    total_departments = Repo.aggregate(Department, :count, :id)

    # Join departments with user_profiles to count staff
    dept_counts =
      from(d in Department,
        left_join: up in UserProfile, on: up.department_id == d.id,
        group_by: d.id,
        select: {d.id, count(up.id)}
      )
      |> Repo.all()

    # Convert to map for easier calculations
    dept_map = Map.new(dept_counts)

    active_departments = dept_map |> Enum.count(fn {_id, count} -> count > 0 end)
    inactive_departments = dept_map |> Enum.count(fn {_id, count} -> count == 0 end)
    total_staff = dept_map |> Enum.reduce(0, fn {_id, count}, acc -> acc + count end)

    %{
      total_departments: total_departments,
      active_departments: active_departments,
      inactive_departments: inactive_departments,
      total_staff: total_staff
    }
  end

  @doc """
  Lists departments with optional search and pagination.

  Params can include:
    - "page" => integer or string
    - "search" => string to search department name or code
  """
  def list_departments_paginated(params \\ %{}) do
    page = Map.get(params, "page", 1) |> to_int()
    search = Map.get(params, "search", "")
    per_page = @per_page
    offset = (page - 1) * per_page

    # Base query
    base_query = from(d in Department, order_by: [desc: d.inserted_at])

    # Apply search filter
    filtered_query =
      if search != "" do
        like_search = "%#{search}%"
        from d in base_query,
          where: ilike(d.name, ^like_search) or ilike(d.code, ^like_search)
      else
        base_query
      end

    # Total count
    total =
      filtered_query
      |> exclude(:order_by)
      |> Repo.aggregate(:count, :id)

    # Paginated results
    departments_page =
      filtered_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()

    total_pages = ceil(total / per_page)

    %{
      departments_page: departments_page,
      total: total,
      total_pages: total_pages,
      page: page
    }
  end

  ## ----------------------
  ## UserProfile functions
  ## ----------------------

  @doc """
List all users, with their profile (if any) and department preloaded.
If a user has no profile, you’ll still get the user with `user_profile = nil`.
"""
  def list_user_profiles do
    import Ecto.Query

    # Get all users first
    users = Repo.all(User)

    # Then preload profiles and departments for each user individually
    # This handles the case where user_profile might be nil
    users
    |> Enum.map(fn user ->
      Repo.preload(user, user_profile: [:department])
    end)
  end

  @doc "Get a single user profile by ID"
  def get_user_profile!(id) do
    UserProfile
    |> Repo.get!(id)
    |> Repo.preload([:user, :department])
  end

  def get_user_with_profile!(id) do
    Repo.get!(User, id)
    |> Repo.preload(user_profile: [:department])
  end

  @doc "Delete a user profile"
  def delete_user_profile(%UserProfile{} = user_profile), do: Repo.delete(user_profile)

  @doc "Returns changeset for a user profile"
  def change_user_profile(%UserProfile{} = user_profile, attrs \\ %{}), do: UserProfile.changeset(user_profile, attrs)

  @doc """
  Returns the user's profile if it exists; otherwise returns a new struct
  with `user_id` prefilled. Useful for forms.
  """
  def get_or_init_user_profile_for_user(%User{id: user_id} = user) do
    user = Repo.preload(user, :user_profile)

    case user.user_profile do
      %UserProfile{} = profile -> profile
      _ -> %UserProfile{user_id: user_id}
    end
  end

  @doc """
  Creates or updates the profile for the given user.

  Ensures required fields such as `user_id` and `last_seen_at` are present
  to satisfy validations in the profile changeset.
  """
  def upsert_user_profile_for_user(%User{} = user, attrs) when is_map(attrs) do
    profile = get_or_init_user_profile_for_user(user)

    attrs =
      attrs
      |> Map.put_new("user_id", user.id)
      |> Map.put_new("last_seen_at", profile.last_seen_at || DateTime.utc_now())

    changeset = UserProfile.changeset(profile, attrs)

    case profile do
      %UserProfile{id: nil} -> Repo.insert(changeset)
      %UserProfile{} -> Repo.update(changeset)
    end
  end

  ## ----------------------
  ## User statistics
  ## ----------------------

  @doc """
  Returns user statistics as a map:
    - total_users: total number of users
    - admins: number of users with role "admin"
    - users: number of users with role "user" (staff)
    - active_users: number of users who were active in last 30 days
  """
  def user_stats do
    # Total users
    total_users = Repo.aggregate(User, :count, :id)

    # Admin users
    admins =
      from(u in User,
        where: u.role == "admin"
      )
      |> Repo.aggregate(:count, :id)

    # Staff (non-admin) users
    staff =
      from(u in User,
        where: u.role != "admin"
      )
      |> Repo.aggregate(:count, :id)

    # Active users: last_seen_at within last 30 days (from UserProfile)
    thirty_days_ago =
      DateTime.utc_now() |> DateTime.add(-30 * 24 * 60 * 60, :second)

    active_users =
      from(u in User,
        join: p in UserProfile, on: p.user_id == u.id,
        where: not is_nil(p.last_seen_at) and p.last_seen_at >= ^thirty_days_ago
      )
      |> Repo.aggregate(:count, :id)

    %{
      total_users: total_users,
      admins: admins,
      users: staff,
      active_users: active_users
    }
  end

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
  def list_users_paginated(params \\ %{}) do
    page = Map.get(params, "page", 1) |> to_int()
    search = Map.get(params, "search", "")
    role = Map.get(params, "role", "all")
    department = Map.get(params, "department", "all")
    per_page = @per_page
    offset = (page - 1) * per_page

    # Base query
    base_query =
      from u in User,
        order_by: [desc: u.inserted_at]

    # Status filter
    filtered_query =
      if role != "all" do
        from u in base_query, where: u.role == ^role
      else
        base_query
      end

    # Department filter
    filtered_query =
      cond do
        department == "all" ->
          filtered_query

        department == "belum_diisi" ->
          from u in filtered_query,
            left_join: up in assoc(u, :user_profile),
            where: is_nil(up.department_id)

        true ->
          from u in filtered_query,
            join: up in assoc(u, :user_profile),
            where: up.department_id == ^String.to_integer(department)
      end

    # Search filter — use proper joins!
    final_query =
      if search != "" do
        like_search = "%#{search}%"

        from u in filtered_query,
          left_join: up in assoc(u, :user_profile),
          where:
            ilike(u.email, ^like_search) or
            ilike(u.role, ^like_search) or
            ilike(up.employment_status, ^like_search) or
            ilike(up.gender, ^like_search) or
            ilike(up.full_name, ^like_search) or
            ilike(up.phone_number, ^like_search) or
            ilike(up.position, ^like_search),
          distinct: u.id,
          select: u
      else
        filtered_query
      end

    # Total count
    total =
      final_query
      |> exclude(:order_by)
      |> Repo.aggregate(:count, :id)

    # Paginated results, preloading associations correctly
    users_page =
      final_query
      |> limit(^per_page)
      |> offset(^offset)
      |> Repo.all()
      |> Repo.preload([user_profile: :department])

    total_pages = ceil(total / per_page)

    %{
      users_page: users_page,
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

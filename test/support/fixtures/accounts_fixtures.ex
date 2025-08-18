defmodule Spato.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Spato.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Spato.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a department.
  """
  def department_fixture(attrs \\ %{}) do
    {:ok, department} =
      attrs
      |> Enum.into(%{
        code: "some code",
        name: "some name"
      })
      |> Spato.Accounts.create_department()

    department
  end

  @doc """
  Generate a user_profile.
  """
  def user_profile_fixture(attrs \\ %{}) do
    {:ok, user_profile} =
      attrs
      |> Enum.into(%{
        address: "some address",
        date_joined: ~D[2025-08-17],
        dob: ~D[2025-08-17],
        employment_status: "some employment_status",
        full_name: "some full_name",
        gender: "some gender",
        ic_number: "some ic_number",
        is_active: true,
        last_login_at: ~U[2025-08-17 04:31:00Z],
        phone_number: "some phone_number",
        position: "some position",
        profile_picture_url: "some profile_picture_url"
      })
      |> Spato.Accounts.create_user_profile()

    user_profile
  end
end

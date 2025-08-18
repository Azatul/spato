defmodule SpatoWeb.UserProfileLiveTest do
  use SpatoWeb.ConnCase

  import Phoenix.LiveViewTest
  import Spato.AccountsFixtures

  @create_attrs %{position: "some position", address: "some address", full_name: "some full_name", dob: "2025-08-17", ic_number: "some ic_number", gender: "some gender", phone_number: "some phone_number", employment_status: "some employment_status", date_joined: "2025-08-17", profile_picture_url: "some profile_picture_url", last_login_at: "2025-08-17T04:31:00Z", is_active: true}
  @update_attrs %{position: "some updated position", address: "some updated address", full_name: "some updated full_name", dob: "2025-08-18", ic_number: "some updated ic_number", gender: "some updated gender", phone_number: "some updated phone_number", employment_status: "some updated employment_status", date_joined: "2025-08-18", profile_picture_url: "some updated profile_picture_url", last_login_at: "2025-08-18T04:31:00Z", is_active: false}
  @invalid_attrs %{position: nil, address: nil, full_name: nil, dob: nil, ic_number: nil, gender: nil, phone_number: nil, employment_status: nil, date_joined: nil, profile_picture_url: nil, last_login_at: nil, is_active: false}

  defp create_user_profile(_) do
    user_profile = user_profile_fixture()
    %{user_profile: user_profile}
  end

  describe "Index" do
    setup [:create_user_profile]

    test "lists all user_profiles", %{conn: conn, user_profile: user_profile} do
      {:ok, _index_live, html} = live(conn, ~p"/user_profiles")

      assert html =~ "Listing User profiles"
      assert html =~ user_profile.position
    end

    test "saves new user_profile", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/user_profiles")

      assert index_live |> element("a", "New User profile") |> render_click() =~
               "New User profile"

      assert_patch(index_live, ~p"/user_profiles/new")

      assert index_live
             |> form("#user_profile-form", user_profile: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#user_profile-form", user_profile: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/user_profiles")

      html = render(index_live)
      assert html =~ "User profile created successfully"
      assert html =~ "some position"
    end

    test "updates user_profile in listing", %{conn: conn, user_profile: user_profile} do
      {:ok, index_live, _html} = live(conn, ~p"/user_profiles")

      assert index_live |> element("#user_profiles-#{user_profile.id} a", "Edit") |> render_click() =~
               "Edit User profile"

      assert_patch(index_live, ~p"/user_profiles/#{user_profile}/edit")

      assert index_live
             |> form("#user_profile-form", user_profile: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#user_profile-form", user_profile: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/user_profiles")

      html = render(index_live)
      assert html =~ "User profile updated successfully"
      assert html =~ "some updated position"
    end

    test "deletes user_profile in listing", %{conn: conn, user_profile: user_profile} do
      {:ok, index_live, _html} = live(conn, ~p"/user_profiles")

      assert index_live |> element("#user_profiles-#{user_profile.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#user_profiles-#{user_profile.id}")
    end
  end

  describe "Show" do
    setup [:create_user_profile]

    test "displays user_profile", %{conn: conn, user_profile: user_profile} do
      {:ok, _show_live, html} = live(conn, ~p"/user_profiles/#{user_profile}")

      assert html =~ "Show User profile"
      assert html =~ user_profile.position
    end

    test "updates user_profile within modal", %{conn: conn, user_profile: user_profile} do
      {:ok, show_live, _html} = live(conn, ~p"/user_profiles/#{user_profile}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit User profile"

      assert_patch(show_live, ~p"/user_profiles/#{user_profile}/show/edit")

      assert show_live
             |> form("#user_profile-form", user_profile: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#user_profile-form", user_profile: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/user_profiles/#{user_profile}")

      html = render(show_live)
      assert html =~ "User profile updated successfully"
      assert html =~ "some updated position"
    end
  end
end

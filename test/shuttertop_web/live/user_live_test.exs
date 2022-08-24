defmodule ShuttertopWeb.UserControllerTest do
  use ShuttertopWeb.ConnCase
  require Logger

  import Phoenix.LiveViewTest

  setup %{conn: conn} = config do
    user = insert_user()

    conn =
      if config[:login] do
        guardian_login(user, :token)
      else
        conn
      end

    {:ok, conn: conn, user: user}
  end

  test "Leaders disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.UserLive.Index))

    assert disconnected_html =~ "usersPage"
    assert render(page_live) =~ "usersPage"
  end

  test "Show user disconnected and connected render", %{conn: conn, user: user} do
    {:ok, page_live, disconnected_html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.UserLive.Show, slug_path(user)))

    assert disconnected_html =~ "userPage"
    assert render(page_live) =~ "userPage"
  end

  @tag login: :same
  test "Follow user disconnected and connected render", %{conn: conn} do
    user1 = insert_user()

    {:ok, live, html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.UserLive.Show, slug_path(user1)))

    assert html =~ "userPage"
    assert render(live) =~ "icons follow-outline"

    ret =
      live
      |> element("#user-follow-#{user1.id}")
      |> render_click()

    assert ret =~ "icons follow"
    assert !(ret =~ "icons follow-outline")
  end

  test "Follow user not logged", %{conn: conn} do
    user1 = insert_user()

    {:ok, live, html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.UserLive.Show, slug_path(user1)))

    assert html =~ "userPage"
    assert render(live) =~ "icons follow-outline"

    ret =
      live
      |> element("#user-follow-#{user1.id}")
      |> render_click()

    assert ret =~ "icons follow-outline"
  end
end

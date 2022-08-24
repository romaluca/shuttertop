defmodule ShuttertopWeb.AdminLiveTest do
  use ShuttertopWeb.ConnCase

  import Phoenix.LiveViewTest

  require Logger

  setup %{conn: _conn} = config do
    if config[:login] do
      user =
        if config[:login] == :admin do
          insert_admin()
        else
          insert_user()
        end

      conn = guardian_login(user, :token)
      {:ok, conn: conn, user: user}
    else
      :ok
    end
  end

  test "Admin page not auth redirected disconnected and connected render", %{conn: conn} do
    assert {:error, {:redirect, %{to: path}}} =
             live(conn, Routes.live_path(conn, ShuttertopWeb.AdminLive.Show))

    assert path == Routes.live_path(conn, ShuttertopWeb.AuthLive.Index)
  end

  @tag login: :same
  test "Admin page not admin redirected disconnected and connected render", %{conn: conn} do
    assert {:error, {:redirect, %{to: path}}} =
             live(conn, Routes.live_path(conn, ShuttertopWeb.AdminLive.Show))

    assert path == Routes.live_path(conn, ShuttertopWeb.ActivityLive.Index)
  end

  @tag login: :admin
  test "Admin page success disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.AdminLive.Show))

    assert disconnected_html =~ "adminPage"
    assert render(page_live) =~ "adminPage"
  end
end

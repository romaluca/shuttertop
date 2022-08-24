defmodule ShuttertopWeb.ActivityLiveTest do
  use ShuttertopWeb.ConnCase

  import Phoenix.LiveViewTest

  require Logger

  alias Shuttertop.{Follows}

  setup %{conn: _conn} = config do
    if config[:login] do
      user1 = insert_user()
      user = insert_user()
      contest = insert_contest(user1)
      photo = insert_photo(user1, contest)

      conn = guardian_login(user, :token)
      {:ok, conn: conn, user: user, contest: contest, photo: photo}
    else
      :ok
    end
  end

  test "Welcome page disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ActivityLive.Index))

    assert disconnected_html =~ "welcomePage"
    assert render(page_live) =~ "welcomePage"
  end

  @tag login: :same
  test "Home page activities disconnected and connected render", %{
    conn: conn,
    contest: contest,
    user: user
  } do
    {:ok, page_live, disconnected_html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ActivityLive.Index))

    assert disconnected_html =~ "No news here?"
    assert render(page_live) =~ "No news here?"
    assert !(disconnected_html =~ contest.name)
    assert !(render(page_live) =~ contest.name)
    Follows.add(contest, user)

    {:ok, page_live, disconnected_html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ActivityLive.Index))

    assert disconnected_html =~ contest.name
    assert render(page_live) =~ contest.name
  end
end

defmodule ShuttertopWeb.Components.FollowTest do
  use ShuttertopWeb.ConnCase

  import Phoenix.LiveViewTest
  alias Shuttertop.Follows

  require Logger

  setup %{conn: conn} = config do
    user1 = insert_user()
    user = insert_user()
    contest = insert_contest(user1)
    photo = insert_photo(user1, contest)

    conn =
      if config[:login] do
        guardian_login(user, :token)
      else
        conn
      end

    {:ok, conn: conn, user: user, user1: user1, contest: contest, photo: photo}
  end

  test "Follow contest not active render test", %{contest: contest, user: user} do
    view =
      render_component(ShuttertopWeb.Components.Follow, %{
        current_user: user,
        entity: contest,
        id: "follow-id"
      })

    assert view =~ "icons follow-outline"
  end

  test "Follow contest active render test", %{contest: contest, user: user} do
    {:ok, contest} = Follows.add(contest, user)

    view =
      render_component(ShuttertopWeb.Components.Follow, %{
        current_user: user,
        entity: contest,
        id: "follow-id"
      })

    assert !(view =~ "icons follow-outline")
    assert view =~ "icons follow"
  end

  test "Follow user not active render test", %{user: user} do
    view =
      render_component(ShuttertopWeb.Components.Follow, %{
        current_user: nil,
        entity: user,
        id: "follow-id"
      })

    assert view =~ "icons follow-outline"
  end

  test "Follow user active render test", %{user: user, user1: user1} do
    {:ok, user1} = Follows.add(user1, user)

    view =
      render_component(ShuttertopWeb.Components.Follow, %{
        current_user: user,
        entity: user1,
        id: "follow-id"
      })

    assert !(view =~ "icons follow-outline")
    assert view =~ "icons follow"
  end
end

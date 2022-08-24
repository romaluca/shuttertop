defmodule ShuttertopWeb.Components.VoteTest do
  use ShuttertopWeb.ConnCase

  import Phoenix.LiveViewTest
  alias Shuttertop.Votes

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

    {:ok, conn: conn, user: user, contest: contest, photo: photo}
  end

  test "Vote not actived render test", %{user: user, photo: photo} do
    view =
      render_component(ShuttertopWeb.Components.Vote, %{
        photo: photo,
        current_user: user,
        label_mode: true,
        id: "buttonVote-#{photo.id}"
      })

    assert !(view =~ "top-icon icons heart_fill")
    assert view =~ "top-icon icons heart"
  end

  test "Vote actived render test", %{user: user, photo: photo} do
    {:ok, photo} = Votes.add(photo, user)

    view =
      render_component(ShuttertopWeb.Components.Vote, %{
        photo: photo,
        current_user: user,
        label_mode: true,
        id: "buttonVote-#{photo.id}"
      })

    assert view =~ "top-icon icons heart_fill"
  end
end

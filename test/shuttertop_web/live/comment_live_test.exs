defmodule ShuttertopWeb.CommentLiveTest do
  use ShuttertopWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Shuttertop.Posts

  require Logger

  setup %{conn: _conn} = config do
    if config[:login] do
      user = insert_user()
      conn = guardian_login(user, :token)
      {:ok, conn: conn, user: user}
    else
      :ok
    end
  end

  @tag login: :same
  test "Messages page disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.CommentLive.Messages))

    assert disconnected_html =~ "commentsPage"
    assert render(page_live) =~ "commentsPage"
  end

  test "Messages page not logged user disconnected and connected render", %{conn: conn} do
    {:error, {:live_redirect, %{}}} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.CommentLive.Messages))
  end

  @tag login: :same
  test "Messages contains contest topic", %{conn: conn, user: user} do
    contest = insert_contest(user)
    {:ok, %{comment: comment}} = Posts.create_comment(contest, "commento contest!", user)
    {:ok, lv, _} = live(conn, Routes.live_path(conn, ShuttertopWeb.CommentLive.Messages))
    ele = lv |> element("#topic-#{comment.topic_id}")
    assert has_element?(ele)
    assert render_click(ele) =~ "commento contest!"
  end

  @tag login: :same
  test "Messages contains photo topic", %{conn: conn, user: user} do
    contest = insert_contest(user)
    photo = insert_photo(user, contest)
    {:ok, %{comment: comment}} = Posts.create_comment(photo, "commento photo!", user)
    {:ok, lv, _} = live(conn, Routes.live_path(conn, ShuttertopWeb.CommentLive.Messages))
    ele = lv |> element("#topic-#{comment.topic_id}")
    assert has_element?(ele)
    assert render_click(ele) =~ "commento photo!"
  end

  @tag login: :same
  test "Messages contains user topic", %{conn: conn, user: user} do
    user1 = insert_user()
    {:ok, %{comment: comment}} = Posts.create_comment(user, "commento user!", user1)
    {:ok, lv, _} = live(conn, Routes.live_path(conn, ShuttertopWeb.CommentLive.Messages))
    ele = lv |> element("#topic-#{comment.topic_id}")
    assert has_element?(ele)
    assert render_click(ele) =~ "commento user!"
  end

  @tag login: :same
  test "Messages new comment", %{conn: conn, user: user} do
    user1 = insert_user()
    {:ok, %{comment: comment}} = Posts.create_comment(user, "commento user!", user1)
    {:ok, lv, _} = live(conn, Routes.live_path(conn, ShuttertopWeb.CommentLive.Messages))
    ele = lv |> element("#topic-#{comment.topic_id}")
    render_click(ele)

    lv
    |> form("#comment-form", comment: %{"body" => "new comment user"})
    |> render_submit() =~ "new comment user"
  end
end

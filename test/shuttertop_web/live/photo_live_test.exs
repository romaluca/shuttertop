defmodule ShuttertopWeb.PhotoLiveTest do
  use ShuttertopWeb.ConnCase
  import Phoenix.LiveViewTest
  require Logger

  @valid_attrs %{"upload" => "upload.jpg"}

  setup %{conn: conn} = config do
    user = insert_user()
    contest = insert_contest(user)

    conn =
      if config[:login] do
        guardian_login(user, :token)
      else
        conn
      end

    {:ok, conn: conn, user: user, contest: contest}
  end

  @tag login: :same
  test "shows chosen photo", %{conn: conn, user: user, contest: contest} do
    photo = insert_photo(user, contest, @valid_attrs)

    {:ok, live, html} =
      live(
        conn,
        Routes.live_path(
          conn,
          ShuttertopWeb.PhotoLive.Slide,
          "contests",
          slug_path(contest),
          "news",
          photo.id
        )
      )

    assert html =~ user.name
    assert html =~ contest.name
    assert render(live) =~ user.name
  end

  test "renders page not found when id is nonexistent", %{conn: conn, contest: contest} do
    assert_error_sent(:not_found, fn ->
      live(
        conn,
        Routes.live_path(
          conn,
          ShuttertopWeb.PhotoLive.Slide,
          "contests",
          slug_path(contest),
          "news",
          0
        )
      )
    end)
  end

  @tag login: :same
  test "top photo logged user", %{conn: conn, user: user, contest: contest} do
    photo = insert_photo(user, contest, @valid_attrs)

    {:ok, live, _html} =
      live(
        conn,
        Routes.live_path(
          conn,
          ShuttertopWeb.PhotoLive.Slide,
          "contests",
          slug_path(contest),
          "news",
          photo.id
        )
      )

    assert !(render(live) =~ "heart_fill")

    assert live
           |> element("#vote-#{photo.id}")
           |> render_click() =~ "heart_fill"
  end

  test "top photo not logged user", %{conn: conn, user: user, contest: contest} do
    photo = insert_photo(user, contest, @valid_attrs)

    {:ok, live, _html} =
      live(
        conn,
        Routes.live_path(
          conn,
          ShuttertopWeb.PhotoLive.Slide,
          "contests",
          slug_path(contest),
          "news",
          photo.id
        )
      )

    assert !(render(live) =~ "heart_fill")

    ret =
      live
      |> element("#vote-#{photo.id}")
      |> render_click()

    assert !(ret =~ "heart_fill")
  end
end

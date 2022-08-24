defmodule ShuttertopWeb.ContestControllerTest do
  use ShuttertopWeb.ConnCase

  import Phoenix.LiveViewTest

  require Logger

  alias Shuttertop.Contests

  @valid_attrs %{
    "category_id" => 4,
    "description" => "some content",
    "expiry_at" => Timex.to_datetime(Timex.shift(Timex.today(), days: 300)),
    "name" => "cccccccccccccontest"
  }
  @invalid_attrs %{"name" => nil}

  setup %{conn: conn} = config do
    user = insert_user()

    if config[:login] do
      conn = guardian_login(user, :token)
      {:ok, conn: conn, user: user}
    else
      {:ok, conn: conn, user: user}
    end
  end

  test "lists all entries on index disconnected and connected render", %{conn: conn} do
    {:ok, page_live, disconnected_html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ContestLive.Index))

    assert disconnected_html =~ "Categorie"
    assert render(page_live) =~ "Categorie"
  end

  @tag login: :same
  test "renders form for new resources", %{conn: conn, user: _user} do
    {:ok, page_live, disconnected_html} = live(conn, Routes.contest_form_path(conn, :new))
    assert disconnected_html =~ "New contest"
    assert render(page_live) =~ "New contest"
  end

  @tag login: :same
  test "creates resource and redirects when data is valid", %{conn: conn, user: _user} do
    {:ok, live, _html} = live(conn, Routes.contest_form_path(conn, :new))

    response =
      live
      |> form("#contest-form", contest: @valid_attrs)
      |> render_submit()

    assert contest = Contests.get_contest_by(name: @valid_attrs["name"])

    response
    |> follow_redirect(
      conn,
      Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, slug_path(contest))
    )
  end

  @tag login: :same
  test "does not create resource and renders errors when data is invalid", %{
    conn: conn,
    user: _user
  } do
    {:ok, live, _html} = live(conn, Routes.contest_form_path(conn, :new))

    assert live
           |> form("#contest-form", contest: @invalid_attrs)
           |> render_submit() =~ "something wrong, check the errors here"
  end

  test "shows chosen resource", %{conn: conn} do
    contest =
      insert_user()
      |> insert_contest(@valid_attrs)

    {:ok, live, html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, slug_path(contest)))

    assert html =~ contest.name
    assert render(live) =~ contest.name
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent(404, fn ->
      {:ok, _live, _html} =
        live(conn, Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, "423434-dsadf"))
    end)
  end

  @tag login: :same
  test "renders form for editing chosen resource", %{conn: conn, user: user} do
    contest = insert_contest(user, @valid_attrs)
    {:ok, live, html} = live(conn, Routes.contest_form_path(conn, :edit, id: contest.id))
    assert html =~ contest.name
    assert render(live) =~ contest.name
  end

  @tag login: :same
  test "updates chosen resource and redirects when data is valid", %{conn: conn, user: user} do
    upd_attrs = %{@valid_attrs | "description" => "some content updated"}
    contest = insert_contest(user, @valid_attrs)
    {:ok, live, _html} = live(conn, Routes.contest_form_path(conn, :edit, id: contest.id))

    live
    |> form("#contest-form", contest: upd_attrs)
    |> render_submit()
    |> follow_redirect(
      conn,
      Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, slug_path(contest))
    )

    assert contest = Contests.get_contest_by(name: @valid_attrs["name"])
    assert contest.description == upd_attrs["description"]
  end

  @tag login: :same
  test "does not update chosen resource and renders errors when data is invalid", %{
    conn: conn,
    user: user
  } do
    contest = insert_contest(user, @valid_attrs)
    {:ok, live, _html} = live(conn, Routes.contest_form_path(conn, :edit, id: contest.id))

    assert live
           |> form("#contest-form", contest: @invalid_attrs)
           |> render_submit() =~ "something wrong, check the errors here"
  end

  @tag login: :same
  test "upload photo in contest page", %{
    conn: conn,
    user: user
  } do
    contest = insert_contest(user, @valid_attrs)

    {:ok, _live, _html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, slug_path(contest)))
  end

  @tag login: :same
  test "Follow contest disconnected and connected render", %{conn: conn, user: _user} do
    user1 = insert_user()
    contest = insert_contest(user1, @valid_attrs)

    {:ok, live, html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, slug_path(contest)))

    assert html =~ "contestPage"
    assert render(live) =~ "icons follow-outline"

    ret =
      live
      |> element("#contest-follow-#{contest.id}")
      |> render_click()

    assert ret =~ "icons follow"
    assert !(ret =~ "icons follow-outline")
  end

  test "Follow contest not logged", %{conn: conn, user: _user} do
    user1 = insert_user()
    contest = insert_contest(user1, @valid_attrs)

    {:ok, live, html} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, slug_path(contest)))

    assert html =~ "contestPage"
    assert render(live) =~ "icons follow-outline"

    ret =
      live
      |> element("#contest-follow-#{contest.id}")
      |> render_click()

    assert ret =~ "icons follow-outline"
  end

  # @tag login: :same
  # test "deletes chosen resource", %{conn: conn, user: user} do
  #   contest = insert_contest(user, @valid_attrs)
  #   conn = delete(conn, Routes.contest_path(conn, :delete, contest))
  #   assert redirected_to(conn) == Routes.contest_path(conn, :index)
  #   refute Repo.get(Contest, contest.id)
  # end
end

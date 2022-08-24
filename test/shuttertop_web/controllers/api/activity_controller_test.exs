defmodule ShuttertopWeb.Api.ActivityControllerTest do
  use ShuttertopWeb.ConnCase
  require Logger
  require Shuttertop.Constants

  alias Shuttertop.{Follows, Guardian, Votes}
  alias Shuttertop.Activities.Activity
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Constants, as: Const

  @valid_vote_attrs %{"type" => "vote"}
  @valid_follow_contest_attrs %{"type" => "follow", "entity" => "contest"}
  @valid_follow_user_attrs %{"type" => "follow", "entity" => "user"}
  @invalid_attrs %{"type" => "cippa"}

  setup %{conn: conn} = config do
    if config[:login] do
      user = insert_user()
      user2 = insert_user()
      {:ok, jwt, _} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("x-api-key", Application.get_env(:shuttertop, :api_key))
        |> put_req_header("authorization", "Bearer #{jwt}")

      contest = insert_contest(user)
      photo = insert_photo(user, contest)
      {:ok, _jwt, _} = Guardian.encode_and_sign(user)

      {:ok, conn: conn, user: user, contest: contest, photo: photo, user2: user2}
    else
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("x-api-key", Application.get_env(:shuttertop, :api_key))

      {:ok, conn: conn}
    end
  end

  @tag login: :same
  test "create vote when data is valid", %{
    conn: conn,
    user: user,
    contest: _contest,
    photo: photo
  } do
    attrs = Map.merge(@valid_vote_attrs, %{"id" => photo.id})
    conn = post conn, Routes.api_activity_path(conn, :create), attrs
    body = json_response(conn, :created)
    assert body["votes_count"] == 1
    assert body["position"] == 1
    attrs = %{user_id: user.id, type: Const.action_vote()}
    assert Repo.get_by(Activity, attrs)
  end

  @tag login: :same
  test "remove vote when data is valid", %{
    conn: conn,
    user: user,
    contest: _contest,
    photo: photo
  } do
    {:ok, %Photo{} = photo} = Votes.add(photo, user)
    conn = delete conn, Routes.api_activity_path(conn, :delete, photo.id), @valid_vote_attrs
    body = json_response(conn, :ok)
    Logger.warn(inspect(body))
    assert body["votes_count"] == 0
  end

  @tag login: :same
  test "create follow_contest when data is valid", %{
    conn: conn,
    user: user,
    contest: contest,
    photo: _photo
  } do
    attrs = Map.merge(@valid_follow_contest_attrs, %{"id" => contest.id})
    conn = post conn, Routes.api_activity_path(conn, :create), attrs
    _body = json_response(conn, :created)
    attrs = %{user_id: user.id, contest_id: contest.id, type: Const.action_follow_contest()}
    assert Repo.get_by(Activity, attrs)
  end

  @tag login: :same
  test "remove follow_contest when data is valid", %{
    conn: conn,
    user: user,
    contest: contest,
    photo: _photo
  } do
    {:ok, %Contest{} = contest} = Follows.add(contest, user)

    conn =
      delete conn,
             Routes.api_activity_path(conn, :delete, contest.id),
             @valid_follow_contest_attrs

    _body = json_response(conn, :ok)
  end

  @tag login: :same
  test "create follow_user when data is valid", %{
    conn: conn,
    user: user,
    contest: _contest,
    photo: _photo,
    user2: user2
  } do
    attrs = Map.merge(@valid_follow_user_attrs, %{"id" => user2.id})
    conn = post conn, Routes.api_activity_path(conn, :create), attrs
    _body = json_response(conn, :created)
    attrs = %{user_to_id: user2.id, user_id: user.id, type: Const.action_follow_user()}
    assert Repo.get_by(Activity, attrs)
  end

  @tag login: :same
  test "remove follow_user when data is valid", %{
    conn: conn,
    user: user,
    contest: _contest,
    photo: _photo,
    user2: user2
  } do
    {:ok, user2} = Follows.add(user2, user)

    conn =
      delete conn, Routes.api_activity_path(conn, :delete, user2.id), @valid_follow_user_attrs

    _body = json_response(conn, :ok)
  end

  @tag login: :same
  test "create when data is invalid", %{conn: conn, user: _user, contest: _contest, photo: photo} do
    attrs = Map.merge(@invalid_attrs, %{"id" => photo.id})
    conn = post conn, Routes.api_activity_path(conn, :create), attrs
    _body = json_response(conn, 404)
  end

  @tag login: :same
  test "delete when data is invalid", %{conn: conn, user: user, contest: _contest, photo: photo} do
    {:ok, %Photo{} = photo} = Votes.add(photo, user)
    conn = delete conn, Routes.api_activity_path(conn, :delete, photo.id), @invalid_attrs
    _body = json_response(conn, 404)
  end

  @tag login: :same
  test "vote expired contest", %{conn: conn, user: _user, contest: contest, photo: photo} do
    contest =
      Ecto.Changeset.change(contest,
        expiry_at: Timex.to_datetime(Timex.shift(Timex.today(), days: -3))
      )

    Repo.update!(contest)
    attrs = Map.merge(@valid_vote_attrs, %{"id" => photo.id})
    conn = post conn, Routes.api_activity_path(conn, :create), attrs
    body = json_response(conn, 422)
    assert body["errors"] != %{}
  end
end

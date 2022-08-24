defmodule ShuttertopWeb.Api.ContestControllerTest do
  use ShuttertopWeb.ConnCase

  require Logger

  alias Shuttertop.Contests
  alias Shuttertop.Guardian

  @valid_attrs %{
    "category_id" => 4,
    "description" => "some content",
    "expiry_at" => Timex.to_datetime(Timex.shift(Timex.today(), days: 300)),
    "name" => "ccccccccccccc",
    "url" => "some content"
  }
  @invalid_attrs %{"name" => nil}

  setup %{conn: conn} = config do
    api_key = Application.get_env(:shuttertop, :api_key)

    if config[:login] do
      user = insert_user()
      {:ok, jwt, _} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("x-api-key", api_key)
        |> put_req_header("authorization", "Bearer #{jwt}")

      {:ok, conn: conn, user: user}
    else
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("x-api-key", api_key)

      {:ok, conn: conn}
    end
  end

  @tag login: :same
  test "lists all contests on index", %{conn: conn} do
    conn = get(conn, Routes.api_contest_path(conn, :index))
    json_response(conn, :ok)
  end

  test "lists all contests on index without user error", %{conn: conn} do
    conn = get(conn, Routes.api_contest_path(conn, :index))
    json_response(conn, :unauthorized)
  end

  @tag login: :same
  test "does not create contest and renders errors when name exists and the contest is in progress",
       %{conn: conn, user: _user} do
    conn2 = post(conn, Routes.api_contest_path(conn, :create), contest: @valid_attrs)
    json_response(conn2, :created)
    attrs = Map.new(@valid_attrs, fn {k, v} -> {String.to_atom(k), v} end)
    assert Contests.get_contest_by(attrs)

    conn = post(conn, Routes.api_contest_path(conn, :create), contest: @valid_attrs)

    assert %{
             "errors" => %{"name" => [["Contest in corso", %{}]]}
           } = json_response(conn, :unprocessable_entity)
  end

  @tag login: :same
  test "create contest with second edition by name", %{conn: conn, user: _user} do
    conn2 = post(conn, Routes.api_contest_path(conn, :create), contest: @valid_attrs)
    body = json_response(conn2, :created)
    assert body["edition"] == 1
    attrs = Map.new(@valid_attrs, fn {k, v} -> {String.to_atom(k), v} end)
    contest = Contests.get_contest_by(attrs)
    close_contest(contest)

    conn =
      post(conn, Routes.api_contest_path(conn, :create),
        contest: Map.put(@valid_attrs, "name", "Ccccccccccccc ")
      )

    body = json_response(conn, :created)
    assert body["edition"] == 2
  end

  @tag login: :same
  test "create contest with second edition by contest_id", %{conn: conn, user: _user} do
    conn2 = post(conn, Routes.api_contest_path(conn, :create), contest: @valid_attrs)
    body = json_response(conn2, :created)
    assert body["edition"] == 1
    attrs = Map.new(@valid_attrs, fn {k, v} -> {String.to_atom(k), v} end)
    contest = Contests.get_contest_by(attrs)
    close_contest(contest)

    attrs =
      @valid_attrs
      |> Map.put("contest_id", contest.id)
      |> Map.put("name", "ciaosaf")

    conn = post(conn, Routes.api_contest_path(conn, :create), contest: attrs)

    body = json_response(conn, :created)
    assert body["edition"] == 2
    assert body["name"] == contest.name
  end

  @tag login: :same
  test "create contest with second edition by contest_id not existent render error", %{
    conn: conn,
    user: _user
  } do
    attrs =
      @valid_attrs
      |> Map.put("contest_id", 1000)

    conn = post(conn, Routes.api_contest_path(conn, :create), contest: attrs)

    assert %{
             "errors" => %{"name" => ["Contest di riferimento non trovato"]}
           } = json_response(conn, :unprocessable_entity)
  end

  @tag login: :same
  test "creates contest and redirects when data is valid", %{conn: conn, user: _user} do
    conn = post(conn, Routes.api_contest_path(conn, :create), contest: @valid_attrs)
    json_response(conn, :created)
    attrs = Map.new(@valid_attrs, fn {k, v} -> {String.to_atom(k), v} end)
    assert Contests.get_contest_by(attrs)
  end

  @tag login: :same
  test "does not create contest and renders errors when data is invalid", %{
    conn: conn,
    user: _user
  } do
    conn = post(conn, Routes.api_contest_path(conn, :create), contest: @invalid_attrs)
    assert json_response(conn, :unprocessable_entity)
  end

  @tag login: :same
  test "updates chosen contest when data is valid", %{conn: conn, user: user} do
    contest = insert_contest(user, @valid_attrs)
    conn = put(conn, Routes.api_contest_path(conn, :update, contest.id), contest: @valid_attrs)
    body = json_response(conn, :ok)
    assert body["name"] == contest.name
    attrs = Map.new(@valid_attrs, fn {k, v} -> {String.to_atom(k), v} end)
    assert Contests.get_contest_by(attrs)
  end

  # @tag login: :same
  # test "updates chosen contest when data is invalid", %{conn: conn, user: user} do
  #   contest = insert_contest(user, @valid_attrs)
  #   conn = put(conn, Routes.api_contest_path(conn, :update, contest.id), contest: %{"name" => ""})
  #   json_response(conn, :unprocessable_entity)
  # end

  @tag login: :same
  test "updates chosen contest with another user error", %{conn: conn, user: _user} do
    user2 = insert_user()
    contest = insert_contest(user2, @valid_attrs)
    conn = put(conn, Routes.api_contest_path(conn, :update, contest.id), contest: @valid_attrs)
    assert json_response(conn, :unauthorized)
  end

  @tag login: :same
  test "shows chosen resource", %{conn: conn, user: user} do
    contest = insert_contest(user, @valid_attrs)
    conn = get(conn, Routes.api_contest_path(conn, :show, contest))
    _body = json_response(conn, :ok)
  end

  @tag login: :same
  test "contest show not found", %{conn: conn} do
    assert_error_sent(:not_found, fn ->
      get(conn, Routes.api_contest_path(conn, :show, -1))
    end)
  end
end

defmodule ShuttertopWeb.Api.PhotoControllerTest do
  use ShuttertopWeb.ConnCase

  require Logger

  alias Shuttertop.Photos
  alias Shuttertop.Guardian

  @valid_attrs %{"upload" => "upload.jpg"}
  @invalid_attrs %{"upload" => nil}

  setup %{conn: conn} = config do
    user = insert_user(%{language: config[:login_locale] || "en"})
    contest = insert_contest(user)

    _upload =
      insert_upload(user, %{
        "contest_id" => contest.id,
        "expiry_at" => Timex.to_datetime(Timex.shift(Timex.today(), days: 300)),
        "name" => "upload.jpg",
        "type" => 2
      })

    if config[:login] do
      {:ok, jwt, _} = Guardian.encode_and_sign(user)

      conn =
        put_req_header(conn, "accept", "application/json")
        |> put_req_header("authorization", "Bearer #{jwt}")
        |> put_req_header("x-api-key", Application.get_env(:shuttertop, :api_key))

      {:ok, conn: conn, user: user, contest: contest}
    else
      conn =
        put_req_header(conn, "accept", "application/json")
        |> put_req_header("x-api-key", Application.get_env(:shuttertop, :api_key))

      {:ok, conn: conn, user: user, contest: contest}
    end
  end

  @tag login: :same
  test "creates photo when data is valid", %{conn: conn, user: _user, contest: contest} do
    attrs = Map.merge(@valid_attrs, %{"contest_id" => contest.id})
    conn = post(conn, Routes.api_photo_path(conn, :create), photo: attrs)
    response = json_response(conn, :created)
    assert response["upload"] == @valid_attrs["upload"]
    attrs = Map.new(@valid_attrs, fn {k, v} -> {String.to_atom(k), v} end)
    assert Photos.get_photo_by!(attrs)
  end

  @tag login: :same
  test "does not create photo when data is invalid", %{conn: conn} do
    conn = post(conn, Routes.api_photo_path(conn, :create), photo: @invalid_attrs)
    assert json_response(conn, :unprocessable_entity)
  end

  # @tag login: :same
  # test "does not create a second photo", %{conn: conn, user: user, contest: contest} do
  #   attrs = Map.merge(@valid_attrs, %{"contest_id" => contest.id})
  #   insert_photo(user, attrs)
  #   conn = post(conn, Routes.api_photo_path(conn, :create), photo: attrs)
  #   assert json_response(conn, :unprocessable_entity)
  # end

  @tag login: :same, login_locale: "en"
  test "does not create a photo when contest is expired", %{conn: conn, user: user} do
    c_name = "c#{Base.encode16(:crypto.strong_rand_bytes(8))}"

    contest =
      user
      |> insert_contest(%{
        "category_id" => 4,
        "description" => "some content",
        "expiry_at" => Timex.to_datetime(Timex.shift(Timex.today(), days: 2)),
        "name" => c_name,
        "upload" => "some content",
        "url" => "some content"
      })
      |> Ecto.Changeset.change(
        expiry_at: Timex.to_datetime(Timex.shift(Timex.today(), days: -300))
      )
      |> Repo.update!()

    attrs = Map.merge(@valid_attrs, %{"contest_id" => contest.id})
    conn = post(conn, Routes.api_photo_path(conn, :create), photo: attrs)
    ret = json_response(conn, :unprocessable_entity)
    assert ret
  end

  @tag login: :same
  test "show photo valid", %{conn: conn, user: user, contest: contest} do
    photo = insert_photo(user, contest, @valid_attrs)
    conn = get(conn, Routes.api_photo_path(conn, :show, photo))
    json_response(conn, :ok)
  end

  test "show photo without user error", %{conn: conn, user: user, contest: contest} do
    photo = insert_photo(user, contest, @valid_attrs)
    conn = get(conn, Routes.api_photo_path(conn, :show, photo))
    json_response(conn, :unauthorized)
  end

  @tag login: :same
  test "updates chosen photo when data is valid", %{conn: conn, user: user, contest: contest} do
    photo = insert_photo(user, contest, @valid_attrs)
    conn = put(conn, Routes.api_photo_path(conn, :update, photo), photo: %{"name" => "ciao"})
    body = json_response(conn, :ok)
    assert body["name"] == "ciao"
  end

  @tag login: :same
  test "updates chosen photo when data is invalid", %{conn: conn, user: user, contest: contest} do
    photo = insert_photo(user, contest, @valid_attrs)
    conn = put(conn, Routes.api_photo_path(conn, :update, photo), photo: %{"upload" => ""})
    body = json_response(conn, :ok)
    assert body["upload"] == "upload.jpg"
  end

  @tag login: :same
  test "updates chosen photo with another user error", %{conn: conn, contest: contest} do
    user2 = insert_user()
    photo = insert_photo(user2, contest)
    conn = put(conn, Routes.api_photo_path(conn, :update, photo), photo: %{"name" => "ciao"})
    assert json_response(conn, :unauthorized)
  end

  @tag login: :same
  test "delete chosen photo when data is valid", %{conn: conn, user: user, contest: contest} do
    photo = insert_photo(user, contest)
    conn = delete(conn, Routes.api_photo_path(conn, :delete, photo), photo: %{"name" => "ciao"})
    assert conn.status == 204
  end

  @tag login: :same
  test "delete chosen photo fail when different user", %{
    conn: conn,
    user: _user,
    contest: contest
  } do
    user2 = insert_user()
    photo = insert_photo(user2, contest)
    conn = delete(conn, Routes.api_photo_path(conn, :delete, photo), photo: %{"name" => "ciao"})
    assert conn.status == 401
  end
end

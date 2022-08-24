defmodule ShuttertopWeb.Api.UserControllerTest do
  use ShuttertopWeb.ConnCase
  require Logger

  # alias Shuttertop.Accounts
  # alias Shuttertop.Accounts.User
  alias Shuttertop.Guardian

  @valid_attrs %{
    name: "alfonso",
    email: "gieanni@sdf.it",
    authorizations: [%{password: "lucaaaaa", password_confirmation: "lucaaaaa"}]
  }

  @invalid_attrs %{
    name: "alfonso",
    email: "gieanni",
    authorizations: [%{password: "lucaaaaa", password_confirmation: "lucaaaa"}]
  }

  setup %{conn: conn} = config do
    if config[:login] do
      user = insert_user()
      {:ok, jwt, _} = Guardian.encode_and_sign(user)

      conn =
        put_req_header(conn, "accept", "application/json")
        |> put_req_header("x-api-key", Application.get_env(:shuttertop, :api_key))
        |> put_req_header("authorization", "Bearer #{jwt}")

      {:ok, conn: conn, user: user}
    else
      conn =
        put_req_header(conn, "accept", "application/json")
        |> put_req_header("x-api-key", Application.get_env(:shuttertop, :api_key))

      {:ok, conn: conn}
    end
  end

  @tag login: :same
  test "lists all invites on index", %{conn: conn} do
    user1 = insert_user()
    user2 = insert_user()
    _user3 = insert_user()

    conn =
      post(conn, Routes.api_friends_path(conn, :index),
        emails: [user1.email, String.upcase(user2.email)]
      )

    resp = json_response(conn, :ok)
    assert resp["total_entries"] == 2
    u = List.first(resp["users"])
    assert u["email"] == user1.email || u["email"] == user2.email
  end

  test "new user ok", %{conn: conn} do
    %Plug.Conn{assigns: %{user: user}} =
      post(conn, Routes.api_user_path(conn, :create), user: @valid_attrs)

    assert user.name == "alfonso"
  end

  test "invalid new user error", %{conn: conn} do
    conn = post(conn, Routes.api_user_path(conn, :create), user: @invalid_attrs)
    json_response(conn, :unprocessable_entity)
  end

  @tag login: :same
  test "updates chosen contest when data is valid", %{conn: conn, user: user} do
    conn = put(conn, Routes.api_user_path(conn, :update, user), user: @valid_attrs)
    body = json_response(conn, :ok)
    assert body["name"] == @valid_attrs[:name]
  end

  @tag login: :same
  test "updates chosen user when data is invalid", %{conn: conn, user: user} do
    conn = put(conn, Routes.api_user_path(conn, :update, user), user: @invalid_attrs)
    json_response(conn, :unprocessable_entity)
  end
end

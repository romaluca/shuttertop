defmodule ShuttertopWeb.Api.InvitationControllerTest do
  use ShuttertopWeb.ConnCase
  require Logger

  # alias Shuttertop.Accounts
  # alias Shuttertop.Accounts.User
  alias Shuttertop.Guardian

  @valid_attrs %{
    email: "testinvitation@shuttertop.com"
  }

  @invalid_attrs %{
    name: "alfonso"
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
  test "new invitation ok", %{conn: conn, user: _user} do
    conn1 = post(conn, Routes.api_invitation_path(conn, :create), invitation: @valid_attrs)
    json_response(conn1, :created)

    conn2 = post(conn, Routes.api_invitation_path(conn, :create), invitation: @valid_attrs)
    json_response(conn2, :unprocessable_entity)
  end

  @tag login: :same
  test "invalid new user error", %{conn: conn, user: _user} do
    conn = post(conn, Routes.api_user_path(conn, :create), user: @invalid_attrs)
    json_response(conn, :unprocessable_entity)
  end
end

defmodule ShuttertopWeb.Api.DeviceControllerTest do
  use ShuttertopWeb.ConnCase

  require Logger

  alias Shuttertop.Guardian

  @valid_attrs %{
    "platform" => "android",
    "token" => "23432423423423423"
  }
  @invalid_attrs %{"platform" => ""}

  setup %{conn: conn} = config do
    if config[:login] do
      user = insert_user()
      {:ok, jwt, _} = Guardian.encode_and_sign(user)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header(
          "x-api-key",
          Application.get_env(:shuttertop, :api_key)
        )
        |> put_req_header("authorization", "Bearer #{jwt}")

      {:ok, conn: conn, user: user}
    else
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header(
          "x-api-key",
          Application.get_env(:shuttertop, :api_key)
        )

      {:ok, conn: conn}
    end
  end

  @tag login: :same
  test "shows chosen resource", %{conn: conn} do
    conn = get(conn, Routes.api_device_path(conn, :get_info))
    body = json_response(conn, :ok)
    assert body["min_android_version"] == "2"
    assert body["min_ios_version"] == "1"
  end

  @tag login: :same
  test "creates device and redirects when data is valid", %{conn: conn, user: _user} do
    conn = post(conn, Routes.api_device_path(conn, :create), device: @valid_attrs)
    assert json_response(conn, :created)
  end

  @tag login: :same
  test "remove device when data is valid", %{
    conn: conn,
    user: user
  } do
    device = insert_device(user, @valid_attrs)
    conn = delete(conn, Routes.api_device_path(conn, :delete, device.id))
    _body = json_response(conn, :ok)
  end

  @tag login: :same
  test "does not create device and renders errors when data is invalid", %{
    conn: conn,
    user: _user
  } do
    conn = post(conn, Routes.api_device_path(conn, :create), device: @invalid_attrs)
    assert json_response(conn, :unprocessable_entity)
  end

  test "creates device when user not logged error", %{conn: conn} do
    conn = post(conn, Routes.api_device_path(conn, :create), device: @valid_attrs)
    assert json_response(conn, :unauthorized)
  end
end

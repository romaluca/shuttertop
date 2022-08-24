defmodule ShuttertopWeb.Api.AuthControllerTest do
  use ShuttertopWeb.ConnCase
  require Logger

  # alias Shuttertop.Activities
  # alias Shuttertop.Activities.Activity
  alias Shuttertop.Guardian

  setup %{conn: conn} = config do
    conn =
      put_req_header(conn, "accept", "application/json")
      |> put_req_header("x-api-key", Application.get_env(:shuttertop, :api_key))

    if config[:login] do
      user = insert_user()
      {:ok, conn: conn, user: user}
    else
      {:ok, conn: conn}
    end
  end

  test "social auth by token without provider  error", %{conn: conn} do
    test_token = Application.get_env(:shuttertop, ShuttertopWeb.Endpoint)[:facebook_test_token]
    provider = Atom.to_string(:fin)

    _response =
      post(conn, Routes.api_auth_path(conn, :social, provider, test_token))
      |> json_response(:bad_request)
  end

  @tag :skip
  test "facebook social auth by token ok", %{conn: conn} do
    test_token = Application.get_env(:shuttertop, ShuttertopWeb.Endpoint)[:facebook_test_token]

    %Plug.Conn{assigns: %{user: user}} =
      post(conn, Routes.api_auth_path(conn, :social, "facebook", test_token))

    assert user.name == "Margaret Albaihfgfcjij Liangberg"
  end

  @tag :skip
  test "google social auth by token ok", %{conn: conn} do
    [client_id: client_id, client_secret: client_secret] =
      Application.get_env(:ueberauth, Ueberauth.Strategy.Google.OAuth)

    refresh_token =
      Application.get_env(:shuttertop, ShuttertopWeb.Endpoint)[:google_refresh_token]

    body =
      {:form,
       [
         client_id: client_id,
         client_secret: client_secret,
         refresh_token: refresh_token,
         grant_type: "refresh_token"
       ]}

    headers = [{"Content-type", "application/x-www-form-urlencoded"}]

    {:ok, %HTTPoison.Response{body: body}} =
      HTTPoison.post("https://www.googleapis.com/oauth2/v4/token", body, headers, [])

    params =
      body
      |> Poison.decode!()
      |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)

    %Plug.Conn{assigns: %{user: user}} =
      post(conn, Routes.api_auth_path(conn, :social, "google", params[:access_token]))

    assert user.name == "Luca Romagnoli"
  end

  @tag login: :same
  test "authenticate by mail with no credentials error", %{conn: conn, user: _user} do
    conn = post(conn, Routes.api_auth_path(conn, :callback, "identity"))
    assert json_response(conn, :unprocessable_entity)
  end

  @tag login: :same
  test "authenticate by mail with password wrong error", %{conn: conn, user: user} do
    conn =
      post(
        conn,
        Routes.api_auth_path(conn, :callback, "identity", %{
          email: user.email,
          password: "supersecret1"
        })
      )

    assert json_response(conn, :unprocessable_entity)
  end

  @tag login: :same
  test "authenticate by mail ok", %{conn: conn, user: user} do
    conn =
      post(
        conn,
        Routes.api_auth_path(conn, :callback, "identity", %{
          email: user.email,
          password: "supersecret"
        })
      )

    assert json_response(conn, :ok)
  end

  @tag login: :same
  test "logout ok", %{conn: conn, user: user} do
    {:ok, jwt, _} = Guardian.encode_and_sign(user)

    conn =
      put_req_header(conn, "accept", "application/json")
      |> put_req_header("x-api-key", Application.get_env(:shuttertop, :api_key))
      |> put_req_header("authorization", "Bearer #{jwt}")

    conn = delete(conn, Routes.api_auth_path(conn, :logout))
    assert json_response(conn, :ok)
    refute Shuttertop.Guardian.Plug.authenticated?(conn)
  end
end

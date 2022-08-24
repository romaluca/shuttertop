defmodule Shuttertop.Guardian.AuthErrorHandler do
  @moduledoc false
  import Plug.Conn

  require Logger

  @spec auth_error(Plug.Conn.t(), {any, any}, any) :: Plug.Conn.t()
  def auth_error(conn, {type, _reason}, _opts) do
    body = Poison.encode!(%{message: to_string(type)})

    conn
    |> put_resp_header("content-type", "application/json; charset=utf-8")
    |> send_resp(401, body)
  end
end

defmodule Shuttertop.Guardian.AuthErrorHandlerWeb do
  @moduledoc false
  require Logger

  @spec auth_error(Plug.Conn.t(), {any, any}, any) :: Plug.Conn.t()
  def auth_error(conn, {:invalid_token, :token_expired}, _opts) do
    conn
  end

  def auth_error(conn, {type, reason}, _opts) do
    Logger.error("auth_error - type: #{type} reason: #{reason}")
    conn
    |> Phoenix.Controller.put_flash(:error, "You must be signed in to access this page")
    |> Phoenix.Controller.redirect(
      to: ShuttertopWeb.Router.Helpers.auth_path(conn, :login, "identity")
    )
  end
end

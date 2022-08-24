defmodule ShuttertopWeb.Plug.CheckSession do
  @moduledoc false

  import Phoenix.Controller
  import Plug.Conn
  require Shuttertop.Constants
  require Logger

  alias Guardian.Plug
  alias Shuttertop.Constants, as: Const

  def init(opts), do: opts

  def call(conn, _opts) do
    if Guardian.Plug.session_active?(conn) do
      conn
    else
      conn
    end
  end
end

defmodule ShuttertopWeb.Plug.CheckAdmin do
  @moduledoc false

  import Phoenix.Controller
  import Plug.Conn
  require Shuttertop.Constants

  alias Guardian.Plug
  alias Shuttertop.Constants, as: Const

  def init(opts), do: opts

  def call(conn, _opts) do
    current_user = Plug.current_resource(conn)

    if current_user && current_user.type == Const.user_type_admin() do
      conn
    else
      conn
      |> redirect(to: "/")
      |> halt
    end
  end
end

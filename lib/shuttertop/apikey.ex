defmodule Shuttertop.APIKey do
  @moduledoc false

  require Logger
  # import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    # apikey = get_req_header(conn, "x-api-key")
    # api_key_env = Application.get_env(:shuttertop, :api_key)
    # if apikey == [] or List.first(apikey) != api_key_env do
    #   Logger.error("API KEY ERROR #{apikey} != #{api_key_env}")
    #   conn
    #   |> send_resp(404, "Not Found")
    #   |> halt()
    # else
    #   conn
    # end
    conn
  end
end

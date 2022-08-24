defmodule ShuttertopWeb.AuthControllerTest do
  use ShuttertopWeb.ConnCase
  require Logger

  # alias Shuttertop.Activities
  # alias Shuttertop.Activities.Activity

  # @valid_vote_attrs %{"type" => "7"}
  # @valid_follow_contest_attrs %{"type" => "1"}
  # @valid_follow_user_attrs %{"type" => "0"}
  # @invalid_attrs %{ "type" => "9" }

  setup %{conn: conn} = _config do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end
end

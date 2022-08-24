defmodule ShuttertopWeb.Api.ActivityController do
  use ShuttertopWeb, :controller

  alias Shuttertop.{Accounts, Activities, Contests, Follows, Photos, Votes}
  alias Shuttertop.Guardian.Plug
  alias Shuttertop.Photos.Photo

  require Logger

  action_fallback(ShuttertopWeb.Api.FallbackController)

  plug(Guardian.Plug.EnsureAuthenticated)

  def create(conn, %{"type" => type, "id" => id} = params) do
    current_user = Plug.current_resource(conn)
    entity = params["entity"]

    with {:ok, element} <-
           (case {type, entity} do
              {"follow", "user"} ->
                Accounts.get_user_by!([id: id], current_user)
                |> Follows.add(current_user)

              {"follow", "contest"} ->
                Contests.get_contest_by!([id: id], current_user)
                |> Follows.add(current_user)

              {"vote", _} ->
                Photos.get_photo_by!([id: id], current_user)
                |> Votes.add(current_user)

              _ ->
                conn
                |> put_status(:not_found)
                |> json(nil)
            end),
         do: send_response(conn, :created, element, current_user)
  end

  def delete(conn, %{"type" => type, "id" => id} = params) do
    current_user = Plug.current_resource(conn)
    entity = params["entity"]

    with {:ok, element} <-
           (case {type, entity} do
              {"follow", "user"} ->
                Accounts.get_user_by!([id: id], current_user)
                |> Follows.remove(current_user)

              {"follow", "contest"} ->
                Contests.get_contest_by!([id: id], current_user)
                |> Follows.remove(current_user)

              {"vote", _} ->
                Photos.get_photo_by!([id: id], current_user)
                |> Votes.remove(current_user)

              _ ->
                conn
                |> put_status(:not_found)
                |> json(nil)
            end),
         do: send_response(conn, :ok, element, current_user)
  end

  defp send_response(conn, status, element, _current_user) do
    case element do
      %Photo{position: position, votes_count: votes_count} ->
        conn
        |> put_status(status)
        |> json(%{
          position: position,
          votes_count: votes_count
        })

      _ ->
        conn
        |> put_status(status)
        |> json(nil)
    end
  end

  def index(conn, params) do
    current_user = Plug.current_resource(conn)

    with {:ok, activity_params} <- activities_params(%{}, params),
         page = Activities.get_latest_activities(activity_params, current_user) do
      render(
        conn,
        "index.json",
        activities: page.entries,
        page_number: page.page_number,
        page_size: page.page_size,
        total_pages: page.total_pages,
        total_entries: page.total_entries,
        more: page.more
      )
    end
  end

  def notifies(conn, params) do
    current_user = Plug.current_resource(conn)

    page =
      case params["type"] do
        "score" ->
          Activities.get_latest_scores(current_user, params)

        _ ->
          Accounts.reset_notify_count(current_user)
          Activities.get_latest_notifies(current_user, params)
      end

    render(
      conn,
      "index.json",
      current_user: current_user,
      activities: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries,
      more: page.more
    )
  end
end

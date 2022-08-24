defmodule ShuttertopWeb.Api.ContestController do
  use ShuttertopWeb, :controller

  alias Shuttertop.{
    Activities,
    Accounts,
    Authorizer,
    Contests,
    Follows,
    Photos,
    Posts,
    Uploads
  }

  alias Shuttertop.Guardian.Plug
  alias Shuttertop.Jobs.UserMailerJob
  require Logger

  action_fallback(ShuttertopWeb.Api.FallbackController)

  plug(
    Guardian.Plug.EnsureAuthenticated
    when action in [:show, :index, :create, :update, :report, :delete]
  )

  def show(conn, %{"id" => id, "section" => section} = params) do
    current_user = Plug.current_resource(conn)
    contest = Contests.get_contest_by!([id: id], current_user)

    page =
      case section do
        "activities" ->
          params
          |> Map.put("contest_id", contest.id)
          |> Activities.get_latest_activities(current_user)

        "details" ->
          nil
      end

    render(
      conn,
      "show.json",
      contest: contest,
      photos: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries
    )
  end

  def show(conn, %{"id" => id} = params) do
    current_user = Plug.current_resource(conn)
    contest = Contests.get_contest_by!([id: id], current_user)

    page_photos =
      Photos.get_photos(
        %{contest_id: contest.id, page_size: 6, order: :news},
        current_user
      )

    page_leaders =
      Photos.get_photos(
        %{contest_id: contest.id, order: :top, page_size: 3},
        current_user
      )

    user = Accounts.get_user_by!([id: contest.user_id], current_user)
    page_followers = Follows.get_followers(contest, %{page_size: 6})

    page_comments =
      Enum.reverse(Posts.most_recent_comments(contest.topic, %{page_size: 3}, current_user))

    page_activities =
      params
      |> Map.put("contest_id", contest.id)
      |> Map.put("page_size", 6)
      |> Activities.get_latest_activities(current_user)

    photos_user = Photos.get_photos(%{user_id: current_user.id, contest_id: contest.id})

    render(
      conn,
      "show.json",
      contest: contest,
      photos_user: photos_user,
      comments: page_comments,
      photos: page_photos.entries,
      leaders: page_leaders.entries,
      followers: page_followers,
      activities: page_activities,
      user: user
    )
  end

  def index(conn, params) do
    with {:ok, contest_params} <- contests_params(%{}, params),
         current_user <- Plug.current_resource(conn),
         page <- Contests.get_contests(contest_params, current_user) do
      render(
        conn,
        "index.json",
        contests: page.entries,
        page_number: page.page_number,
        page_size: page.page_size,
        total_pages: page.total_pages,
        total_entries: page.total_entries
      )
    end
  end

  def create(conn, %{"contest" => contest_params}) do
    current_user = Plug.current_resource(conn)

    with {:ok, contest} <- Contests.create_contest(contest_params, current_user) do
      conn
      |> put_status(:created)
      |> render("contest.json", contest: contest)
    end
  end

  def update(conn, %{"id" => id, "contest" => contest_params}) do
    current_user = Plug.current_resource(conn)

    with contest = Contests.get_contest_by!(id: id),
         :ok <- Authorizer.authorize(:edit_contest, current_user, contest),
         {:ok, contest} <- Contests.update_contest(contest, contest_params) do
      unless is_nil(contest_params["upload"]) do
        Uploads.delete_upload(contest.upload, current_user)
      end

      render(conn, "contest.json", contest: contest)
    end
  end

  def delete(conn, %{"id" => id}) do
    current_user = Plug.current_resource(conn)

    with contest = Contests.get_contest_by!(id: id),
         :ok <- Authorizer.authorize(:delete_contest, current_user, contest),
         {:ok, _contest} <- Contests.delete_contest(contest) do
      conn
      |> put_status(204)
      |> send_resp(:no_content, "")
    end
  end

  def report(conn, %{"id" => id, "message" => message}) do
    current_user = Plug.current_resource(conn)

    with contest = Contests.get_contest_by!(id: id) do
      UserMailerJob.enqueue_report(contest, current_user, message)

      conn
      |> put_status(200)
      |> send_resp(:no_content, "")
    end
  end

  def share_params(conn, %{"id" => id}) do
    contest = Contests.get_contest_by!(id: id)
    render(conn, "share_params.json", contest: contest)
  end

  def top_week(conn, _params) do
    case Contests.get_contest_by(%{}, nil, %{top_week: true}) do
      nil ->
        json(conn, nil)

      contest ->
        render(conn, "contest.json", contest: contest)
    end
  end
end

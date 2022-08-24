defmodule ShuttertopWeb.Api.CommentController do
  use ShuttertopWeb, :controller
  require Logger

  alias Shuttertop.{Accounts, Contests, Photos, Posts}

  action_fallback(ShuttertopWeb.Api.FallbackController)

  plug(Guardian.Plug.EnsureAuthenticated)

  def create(conn, %{"body" => body, "entity" => entity, "id" => id} = _params) do
    current_user = Shuttertop.Guardian.Plug.current_resource(conn)

    with e <- Posts.get_entity(entity, id),
         {:ok, %{comment: comment}} <- Posts.create_comment(e, body, current_user) do
      comment = Map.put(comment, :user, current_user)

      conn
      |> put_status(:created)
      |> render("comment.json", %{comment: comment})
    end
  end

  def create(_conn, p) do
    Logger.info("#{inspect(p)}")
  end

  def get_topics(conn, %{} = params) do
    current_user = Shuttertop.Guardian.Plug.current_resource(conn)
    Accounts.reset_notify_message_count(current_user)

    with {:ok, topic_params} <- topics_params(%{}, params),
         page <- Posts.list_topics(topic_params, current_user) do
      render(
        conn,
        "topics.json",
        topics: page.entries,
        page_number: page.page_number,
        page_size: page.page_size,
        total_pages: page.total_pages,
        total_entries: page.total_entries
      )
    end
  end

  def index(conn, %{"photo_id" => id} = params) do
    current_user = Shuttertop.Guardian.Plug.current_resource(conn)
    photo = Photos.get_photo_by!([id: id], current_user)
    comments(conn, photo, params, current_user)
  end

  def index(conn, %{"contest_id" => id} = params) do
    current_user = Shuttertop.Guardian.Plug.current_resource(conn)
    contest = Contests.get_contest_by!([id: id], current_user)
    comments(conn, contest, params, current_user)
  end

  def index(conn, %{"user_id" => id} = params) do
    current_user = Shuttertop.Guardian.Plug.current_resource(conn)
    user = Accounts.get_user_by!([id: id], current_user)
    topic_id = Posts.get_topic_id(user.id, current_user.id)

    user =
      user
      |> Map.put(:topic_id, topic_id)

    comments(conn, user, params, current_user)
  end

  defp comments(conn, element, params, current_user) do
    if is_nil(element.topic_id) do
      render(conn, "index.json",
        comments: [],
        page_number: 0,
        page_size: 0,
        total_pages: 0,
        total_entries: 0
      )
    else
      page =
        element.topic_id
        |> Posts.get_topic()
        |> Posts.most_recent_comments(params, current_user, true)

      render(
        conn,
        "index.json",
        comments: Enum.reverse(page.entries),
        page_number: page.page_number,
        page_size: page.page_size,
        total_pages: page.total_pages,
        total_entries: page.total_entries
      )
    end
  end
end

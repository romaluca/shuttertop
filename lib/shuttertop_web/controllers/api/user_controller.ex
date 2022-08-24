defmodule ShuttertopWeb.Api.UserController do
  use ShuttertopWeb, :controller

  require Logger

  alias Ecto.Changeset

  alias Shuttertop.{
    Accounts,
    Activities,
    Authorizer,
    Contests,
    Follows,
    Photos,
    Posts,
    Uploads,
    Votes
  }

  alias Shuttertop.Accounts.BlockedUser
  alias Shuttertop.Guardian.Plug
  alias Shuttertop.Jobs.UserMailerJob

  plug(
    Guardian.Plug.EnsureAuthenticated
    when action in [:update, :index, :show]
  )

  action_fallback(ShuttertopWeb.Api.FallbackController)

  def index(conn, params) do
    current_user = Plug.current_resource(conn)

    page =
      cond do
        !is_nil(params["followers_user_id"]) ->
          Follows.get_followers(Accounts.get_user!(params["followers_user_id"]))

        !is_nil(params["follows_user_id"]) ->
          Follows.get_follows(Accounts.get_user!(params["follows_user_id"]))

        !is_nil(params["followers_contest_id"]) ->
          Follows.get_followers(Contests.get_contest!(params["followers_contest_id"]))

        !is_nil(params["tops_photo_id"]) ->
          Votes.get_recents(Photos.get_photo!(params["tops_photo_id"]))

        true ->
          with {:ok, user_params} <- users_params(%{}, params),
               do: Accounts.get_users(user_params, current_user)
      end

    render(
      conn,
      users: page.entries,
      page_number: page.page_number,
      page_size: page.page_size,
      total_pages: page.total_pages,
      total_entries: page.total_entries,
      emails: !is_nil(params["emails"])
    )
  end

  def show(conn, %{"id" => id}) do
    current_user = Plug.current_resource(conn)
    user = Accounts.get_user_by!(%{id: id}, current_user)

    page_photos =
      Photos.get_photos(
        %{user_id: user.id, page_size: 6, order: :news},
        current_user
      )

    page_contests = Contests.get_contests(%{user_id: user.id, page_size: 3})
    page_follows = Follows.get_follows(user, %{page_size: 6})
    page_followers = Follows.get_followers(user, %{page_size: 6})
    in_progress = Photos.count_photos_inprogress(user.id)
    topic_id = Posts.get_topic_id(user.id, current_user.id)

    best_photo =
      Photos.get_photos(
        %{user_id: user.id, one: 1, order: :top},
        current_user
      )

    render(
      conn,
      "show.json",
      user: Map.put(Map.put(user, :in_progress, in_progress), :topic_id, topic_id),
      photos: page_photos.entries,
      contests: page_contests.entries,
      followers: page_followers,
      follows: page_follows,
      best_photo: best_photo
    )
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, user} <- Accounts.create_user(user_params) do
      {:ok, now} =
        Timex.now()
        |> Timex.format("%Y%m%d%H%M%S", :strftime)

      token = Bcrypt.hash_pwd_salt("#{now}#{user.email}")

      %{provider: "identity", uid: user.email}
      |> Accounts.get_authorization_by()
      |> Changeset.cast(%{recovery_token: token}, [:recovery_token])
      |> Repo.update!()

      UserMailerJob.enqueue_registration_confirm(user)

      conn
      |> put_status(:created)
      |> render("user.json", user: user)
    end
  end

  def update(conn, %{"user" => user_params, "id" => id}) do
    current_user = Plug.current_resource(conn)

    with user = Accounts.get_user!(id),
         :ok <- Authorizer.authorize(:edit_user, current_user, user),
         {:ok, user} <- Accounts.update_user(user, user_params, current_user) do
      if user.upload, do: Activities.trace_first_avatar(user)

      unless is_nil(user_params["upload"]) do
        Uploads.delete_upload(user.upload, current_user)
      end

      render(conn, "user.json", user: user)
    end
  end

  def block(conn, %{"id" => user_to_id}) do
    current_user = Plug.current_resource(conn)
    user_to = Accounts.get_user_by!([id: user_to_id], current_user)

    with {:ok, %BlockedUser{}} <- Accounts.create_blocked_user(user_to, current_user) do
      conn
      |> put_status(:created)
      |> json(%{blocked: true})
    end
  end

  def unblock(conn, %{"id" => user_to_id}) do
    current_user = Plug.current_resource(conn)
    user_to = Accounts.get_user_by!([id: user_to_id], current_user)

    with {:ok} <- Accounts.delete_blocked_user(user_to, current_user) do
      conn
      |> put_status(:ok)
      |> json(%{blocked: false})
    end
  end
end

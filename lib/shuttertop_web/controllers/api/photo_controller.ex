defmodule ShuttertopWeb.Api.PhotoController do
  use ShuttertopWeb, :controller

  alias Shuttertop.{Votes, Accounts, Authorizer, Photos, Posts, Uploads}
  alias Shuttertop.Guardian.Plug
  alias Shuttertop.Jobs.UserMailerJob

  require Logger

  plug(Guardian.Plug.EnsureAuthenticated)

  action_fallback(ShuttertopWeb.Api.FallbackController)

  def show(conn, %{"id" => id}) do
    current_user = Plug.current_resource(conn)
    photo = Photos.get_photo_by!([id: id], current_user)
    user = Accounts.get_user_by([id: photo.user_id], current_user)

    comments =
      Enum.reverse(Posts.most_recent_comments(photo.topic, %{page_size: 3}, current_user))

    tops = Votes.get_recents(photo, %{page_size: 10})
    render(conn, "show.json", photo: photo, comments: comments, user: user, tops: tops)
  end

  def index(conn, params) do
    current_user = Plug.current_resource(conn)

    with {:ok, photo_params} <- photos_params(%{}, params),
         page <- Photos.get_photos(photo_params, current_user) do
      render(
        conn,
        "index.json",
        photos: page.entries,
        page_number: page.page_number,
        page_size: page.page_size,
        total_pages: page.total_pages,
        total_entries: page.total_entries
      )
    end
  end

  def create(conn, %{"photo" => photo_params}) do
    current_user = Plug.current_resource(conn)

    with {:ok, photo} <-
           Photos.create_photo(
             photo_params,
             current_user
           ) do
      Uploads.delete_upload(photo.upload, current_user)

      conn
      |> put_status(:created)
      |> render("photo.json",
        photo:
          Photos.get_photo_by!(
            [id: photo.id],
            current_user
          )
      )
    end
  end

  def update(conn, %{"id" => id, "photo" => photo_params}) do
    current_user = Plug.current_resource(conn)

    with photo = Photos.get_photo_by!(id: id),
         :ok <- Authorizer.authorize(:edit_photo, current_user, photo),
         {:ok, photo} <- Photos.update_photo(photo, photo_params) do
      render(conn, "photo.json", photo: photo)
    end
  end

  def delete(conn, %{"id" => id}) do
    current_user = Plug.current_resource(conn)

    with {:ok, _} <- Photos.delete_photo(id, current_user) do
      conn
      |> put_status(204)
      |> send_resp(:no_content, "")
    end
  end

  def report(conn, %{"id" => id, "message" => message}) do
    current_user = Plug.current_resource(conn)

    with photo = Photos.get_photo_by!(id: id) do
      UserMailerJob.enqueue_report(photo, current_user, message)

      conn
      |> put_status(200)
      |> send_resp(:no_content, "")
    end
  end
end

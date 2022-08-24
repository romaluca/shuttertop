defmodule ShuttertopWeb.ContestLive.Show do
  use ShuttertopWeb, :live_page

  alias Shuttertop.Authorizer
  alias Shuttertop.{Contests, Follows, Photos, Posts, Uploads}
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Posts.Comment

  require Logger

  def render(assigns) do
    ShuttertopWeb.ContestView.render("show.html", assigns)
  end

  def mount(%{"id" => id_slug} = params, _session, socket) do
    id =
      case Integer.parse(id_slug) do
        {id, _} -> id
        _ -> 0
      end

    current_user = socket.assigns.current_user
    contest = Contests.get_contest_by!([id: id], current_user)

    Posts.get_subscribe_name("contest", contest.id, current_user)
    |> Posts.subscribe_topic()

    socket = assign(socket, contest: contest)
    {:ok, get(socket, params)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, get(socket, params)}
  end

  def handle_info({:uploaded, :photo, photo_params}, socket) do
    current_user = socket.assigns.current_user
    photo_params = Map.put(photo_params, "contest_id", socket.assigns.contest.id)

    case Photos.create_photo(photo_params, current_user) do
      {:ok, photo} ->
        Uploads.delete_upload(photo.upload, current_user)
        contest = Shuttertop.Repo.one(Ecto.assoc(photo, :contest))

        {:noreply,
         socket
         |> push_redirect(
           to:
             Routes.live_path(
               socket,
               ShuttertopWeb.PhotoLive.Slide,
               "contests",
               slug_path(contest),
               "news",
               photo.id
             )
         )}

      {:error, :photo, changeset, _} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  def handle_info({:uploaded, :contest, contest_params}, socket) do
    current_user = socket.assigns.current_user
    contest = socket.assigns.contest
    # contest_params = %{"upload" => filename}
    with :ok <- Authorizer.authorize(:edit_contest, current_user, contest),
         {:ok, contest} <- Contests.update_contest(contest, contest_params) do
      Uploads.delete_upload(contest.upload, current_user)
      {:noreply, assign(socket, contest: contest)}
    end
  end

  def handle_info({_, :created, comment}, socket) do
    send_update(ShuttertopWeb.Components.Chat,
      id: "contest-comment-#{socket.assigns.contest.id}",
      new_comment: comment
    )

    {:noreply, socket}
  end

  defp get(socket, params) do
    current_user = socket.assigns.current_user
    contest = socket.assigns.contest
    locale = Gettext.get_locale(ShuttertopWeb.Gettext)

    meta = [
      title: contest.name,
      description: gettext("Un contest fotografico creato da") <> " #{contest.user.name}",
      image: if(is_nil(contest.upload), do: nil, else: "/1200#{locale}628/#{contest.upload}"),
      image_width: 1200,
      image_height: 628,
      url: Routes.live_path(socket, ShuttertopWeb.ContestLive.Show, slug_path(contest))
    ]

    ret =
      case params["section"] do
        "details" ->
          %{}

        "photos" ->
          with {:ok, photo_params} <-
                 photos_params(%{contest_id: contest.id, order: :news}, params),
               do: %{photos: Photos.get_photos(photo_params, current_user)}

        "rank" ->
          with {:ok, photo_params} <-
                 photos_params(%{contest_id: contest.id, order: :top}, params),
               do: %{photos: Photos.get_photos(photo_params, current_user)}

        "comments" ->
          %{
            comments: Posts.most_recent_comments(contest.topic, %{}, current_user),
            comment_changeset: Comment.changeset(%Comment{topic_id: contest.topic_id}),
            topic: if(contest.topic_id, do: Posts.get_topic(contest.topic_id), else: nil)
          }

        _ ->
          %{
            photos:
              Photos.get_photos(
                %{
                  contest_id: contest.id,
                  order: :news,
                  page_size: if(is_nil(contest.winner_id), do: 4, else: 8)
                },
                current_user
              ),
            leaders:
              Photos.get_photos(
                %{contest_id: contest.id, order: :top, page_size: 3},
                current_user
              ),
            followers: Follows.get_followers(contest, %{page_size: 6}),
            comments:
              Enum.reverse(
                Posts.most_recent_comments(contest.topic, %{page_size: 3}, current_user)
              ),
            comment_changeset: Comment.changeset(%Comment{topic_id: contest.topic_id}),
            photos_user:
              if(current_user,
                do: Photos.get_photos(%{user_id: current_user.id, contest_id: contest.id}),
                else: nil
              ),
            topic: if(contest.topic_id, do: Posts.get_topic(contest.topic_id), else: nil)
          }
      end

    contest_changeset = Contest.changeset(%Contest{})
    photo_changeset = Photo.new_changeset(contest.id)

    assign(
      socket,
      Map.merge(
        %{
          contest_changeset: contest_changeset,
          photo_changeset: photo_changeset,
          params: params,
          page_title: page_title(contest, params),
          meta: meta,
          current_user: current_user,
          body_id: "contestPage",
          contest_upload: true,
          app_version: Application.spec(:shuttertop, :vsn)
        },
        ret
      )
    )
  end

  def handle_event("comment-focus", _, socket) do
    {:noreply, socket}
  end

  def handle_event("comment-blur", _, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "delete",
        _,
        %{assigns: %{contest: contest, current_user: current_user}} = socket
      ) do
    case Authorizer.authorize(:delete_contest, current_user, contest) do
      :ok ->
        {:ok, _contest} = Contests.delete_contest(contest)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Contest deleted successfully."))
         |> push_redirect(to: Routes.live_path(socket, ShuttertopWeb.ContestLive.Index))}

      {:error, :contest_with_photos} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("You can't delete a contest with photos."))}
    end
  end

  defp page_title(contest, params) do
    section =
      case params["section"] do
        "activities" -> gettext("novità") <> " ‧ "
        "rank" -> gettext("classifica") <> " ‧ "
        "details" -> gettext("info") <> " ‧ "
        _ -> ""
      end

    "#{contest.name} ‧ " <> section <> gettext("un contest fotografico")
  end
end

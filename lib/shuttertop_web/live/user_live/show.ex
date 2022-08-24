defmodule ShuttertopWeb.UserLive.Show do
  use ShuttertopWeb, :live_page

  alias Shuttertop.{Accounts, Activities, Authorizer, Contests, Follows, Photos, Uploads}
  alias Shuttertop.Accounts.User

  require Logger

  def render(assigns) do
    ShuttertopWeb.UserView.render("show.html", assigns)
  end

  def mount(params, _session, socket) do
    {:ok, get(params, socket)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, get(params, socket)}
  end

  def handle_info({:uploaded, :user, user_params}, socket) do
    current_user = socket.assigns.current_user
    user = socket.assigns.user
    # user_params = %{"upload" => filename}
    with :ok <- Authorizer.authorize(:edit_user, current_user, user),
         {:ok, user} <- Accounts.update_user(user, user_params, current_user) do
      if user.upload, do: Activities.trace_first_avatar(user)
      Uploads.delete_upload(user.upload, current_user)
      {:noreply, assign(socket, user: user)}
    end
  end

  defp get(%{"id" => id_slug} = params, socket) do
    current_user = socket.assigns.current_user

    id =
      case Integer.parse(id_slug) do
        {id, _} -> id
        _ -> 0
      end

    user = Accounts.get_user_by!([id: id], current_user)

    with {:ok, photo_params} <-
           photos_params(%{user_id: user.id, order: :top, one: true}, params),
         top_photo <- Photos.get_photos(photo_params),
         user_changeset <- User.changeset(%User{}) do
      ret =
        case params["section"] do
          "photos" ->
            {:ok, photo_params} = photos_params(%{user_id: user.id}, params)
            %{elements: Photos.get_photos(photo_params, current_user)}

          "contests" ->
            {:ok, contest_params} = contests_params(%{user_id: user.id}, params)
            contest_params = Map.delete(contest_params, :expired)
            %{elements: Contests.get_contests(contest_params, current_user)}

          "followers" ->
            %{followers: Follows.get_followers(user)}

          _ ->
            {:ok, photo_params} =
              photos_params(%{user_id: user.id, page_size: 4, order: :news}, params)

            {:ok, contest_params} = contests_params(%{user_id: user.id, page_size: 8}, params)
            contest_params = Map.delete(contest_params, :expired)

            %{
              photos: Photos.get_photos(photo_params, current_user),
              followers: Follows.get_followers(user, %{page_size: 6}),
              follows: Follows.get_follows(user, %{page_size: 6}),
              contests: Contests.get_contests(contest_params, current_user)
            }
        end

      socket
      |> assign(
        Map.merge(
          %{
            user: user,
            current_user: current_user,
            user_changeset: user_changeset,
            top_photo: top_photo,
            params: params,
            page_title: page_title(user, params),
            body_id: "userPage",
            user_upload: true,
            app_version: Application.spec(:shuttertop, :vsn)
          },
          ret
        )
      )
    end
  end

  def page_title(user, params) do
    section =
      case params["section"] do
        "activities" ->
          gettext("attività") <> " ‧ "

        "contests" ->
          gettext("contests inseriti") <> " ‧ "

        _ ->
          ""
      end

    "#{user.name} ‧ " <> section
  end
end

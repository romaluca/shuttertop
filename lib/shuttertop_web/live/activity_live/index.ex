defmodule ShuttertopWeb.ActivityLive.Index do
  use ShuttertopWeb, :live_page

  require Shuttertop.Constants

  alias Shuttertop.{Accounts, Activities, Contests, Photos}
  alias Shuttertop.Accounts.{Authorization, User}
  alias Shuttertop.Constants, as: Const

  def render(%{current_user: nil} = assigns) do
    ShuttertopWeb.PageView.render("welcome.html", assigns)
  end

  def render(%{is_loading: true} = assigns) do
    ShuttertopWeb.CommonView.render("loading.html", assigns)
  end

  def render(assigns) do
    ShuttertopWeb.ActivityView.render("index.html", assigns)
  end

  def mount(params, _session, socket) do
    case socket.assigns.current_user do
      %User{} ->
        {:ok,
         socket
         |> assign(
           body_id: "activitiesPage",
           page: 1,
           page_title: gettext("Contest fotografici improvvisati e via discorrendo"),
           app_version: Application.spec(:shuttertop, :vsn)
         )
         |> fetch_mount(params)}

      _ ->
        {:ok,
         socket
         |> assign(%{
           body_id: "welcomePage",
           page_title: gettext("Contest fotografici improvvisati e via discorrendo"),
           app_version: Application.spec(:shuttertop, :vsn)
         })
         |> get_welcome(params)}
    end
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, socket |> assign(page: assigns.page + 1) |> fetch(assigns.params)}
  end

  def handle_params(params, _url, %{assigns: %{current_user: nil}} = socket) do
    {:noreply, get_welcome(socket, params)}
  end

  def handle_params(_params, _url, socket) do
    # {:noreply, fetch(socket, params)}
    {:noreply, socket}
  end

  defp fetch_mount(socket, params) do
    if true or connected?(socket) do
      %{assigns: %{current_user: current_user}} = socket

      user_photos =
        Photos.get_photos(
          %{not_expired: true, order: :news, user_id: current_user.id, page_size: 6},
          current_user
        )

      contest_top = Contests.get_contest_by(%{}, nil, %{top_week: true})

      contest_top =
        unless is_nil(contest_top) do
          case Photos.get_photos(
                 %{contest_id: contest_top.id, user_id: current_user.id, one: true},
                 current_user
               ) do
            nil ->
              contest_top

            _ ->
              nil
          end
        else
          nil
        end

      user_contests =
        Contests.get_contests(%{user_id: current_user.id, page_size: 6}, current_user)

      socket
      |> assign(%{
        contest_top: contest_top,
        user_photos: user_photos,
        user_contests: user_contests
      })
      |> fetch(params)
    else
      assign(socket, is_loading: true)
    end
  end

  defp fetch(%{assigns: %{current_user: current_user, page: page}} = socket, params) do
    with {:ok, new_params} <- concat_params(%{page: page}, params) do
      activities = Activities.get_latest_activities(new_params, current_user)

      socket
      |> assign(%{activities: activities, params: params})
    end
  end

  def get_welcome(socket, _params) do
    tops = Contests.get_contests(%{page_size: 3, order: "top"})
    contests_count = Contests.count_contests()
    users_count = Accounts.count_users()
    photo_tops = Photos.get_photos(%{page_size: 4, wins: true})
    contest_top = Contests.get_contest_by(%{}, nil, %{top_week: true})
    changeset = User.changeset(%User{authorizations: [%Authorization{}]})

    meta = [
      title: "Shuttertop, Contest fotografici improvvisati e via discorrendo",
      description:
        "Scrosta la tua immaginazione. Inserisci il primo contest che ti frulla per la testa e sfida i tuoi amici a colpi di top!",
      url: "",
      image_absolute: true,
      image: Const.site_url() <> Routes.static_path(socket, "/images/shuttertop_back.jpg"),
      image_width: 1280,
      image_height: 861
    ]

    socket
    |> assign(%{
      tops: tops,
      meta: meta,
      contest_top: contest_top,
      librefont: true,
      users_count: users_count,
      photo_tops: photo_tops,
      contests_count: contests_count,
      changeset: changeset
    })
  end
end

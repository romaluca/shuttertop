defmodule ShuttertopWeb.ActivityLive.Notifies do
  use ShuttertopWeb, :live_page

  alias Shuttertop.{Accounts, Activities}

  require Logger

  on_mount ShuttertopWeb.RequiredLiveAuth

  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(
       body_id: "notifiesPage",
       page: 1,
       page_title: gettext("Le tue notifiche"),
       title_bar: gettext("Notifiche"),
       app_version: Application.spec(:shuttertop, :vsn)
     )
     |> fetch_mount(params)}
  end

  def render(%{is_loading: true} = assigns) do
    ShuttertopWeb.CommonView.render("loading.html", assigns)
  end

  def render(assigns) do
    ShuttertopWeb.ActivityView.render("notifies.html", assigns)
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, socket |> assign(page: assigns.page + 1) |> fetch(assigns.params)}
  end

  defp fetch_mount(socket, params) do
    if connected?(socket) do
      %{assigns: %{current_user: current_user}} = socket
      Accounts.reset_notify_count(current_user)

      socket
      |> fetch(params)
    else
      assign(socket, is_loading: true)
    end
  end

  defp fetch(%{assigns: %{current_user: current_user, page: page}} = socket, params) do
    with {:ok, activity_params} <- concat_params(%{page: page}, params),
         notifies = Activities.get_latest_notifies(current_user, activity_params) do
      assign(socket, notifies: notifies, params: params)
    end
  end
end

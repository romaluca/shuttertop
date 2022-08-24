defmodule ShuttertopWeb.AdminLive.Show do
  use ShuttertopWeb, :live_page

  require Logger

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(%{
        current_user: socket.assigns.current_user,
        body_id: "adminPage",
        app_version: Application.spec(:shuttertop, :vsn),
        page_title: gettext("Admin"),
        title_bar: gettext("Admin")
      })

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div style="text-align: center; padding: 1rem;">v.<%= assigns[:app_version] %></div>
    <div class="container pt-5 d-flex justify-content-center" style="text-align: center">
        <.live_component module={ShuttertopWeb.AdminLive.RandomVoteForm}
                    user_id={get_user_id(@current_user)} id="randomVoteForm" />
        <.live_component module={ShuttertopWeb.AdminLive.RemoveAbuseForm}
                    user_id={get_user_id(@current_user)} id="removeAbuseForm" />
        <.live_component module={ShuttertopWeb.AdminLive.EventForm}
                    user_id={get_user_id(@current_user)} id="eventForm" />
        <.live_component module={ShuttertopWeb.AdminLive.Mailer} id="adminMailerForm" />
    </div>
    <div class="pt-5 p-lg-5 container-fluid">
        <div class="row">
        <div class="col-lg-6">
            <.live_component module={ShuttertopWeb.AdminLive.Users} user_id={@current_user.id} id="adminUsersContainer" />
        </div>
        <div class="col-lg-6">
            <.live_component module={ShuttertopWeb.AdminLive.Activities}
                    user_id={@current_user.id} id="adminActivitiesContainer" />
        </div>
        </div>
    </div>
    """
  end
end

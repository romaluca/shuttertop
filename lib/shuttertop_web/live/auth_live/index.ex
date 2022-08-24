defmodule ShuttertopWeb.AuthLive.Index do
  use ShuttertopWeb, :live_page

  require Logger

  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(%{
       body_id: "loginPage",
       error: session["error"],
       current_user: session["current_user"],
       page_title: gettext("Login"),
       app_version: Application.spec(:shuttertop, :vsn)
     })}
  end

  def render(assigns) do
    ~H"""
    <.live_component module={ShuttertopWeb.AuthLive.Login} id="loginComponent" {assigns} />
    """
  end
end

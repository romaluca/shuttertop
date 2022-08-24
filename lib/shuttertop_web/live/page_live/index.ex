defmodule ShuttertopWeb.PageLive.Index do
  use ShuttertopWeb, :live_page

  require Logger

  def mount(params, _session, socket) do
    page = socket.assigns.live_action

    socket =
      socket
      |> assign(%{
        params: params,
        body_id: "#{page}Page",
        app_version: Application.spec(:shuttertop, :vsn)
      })

    if is_nil(params["content"]) do
      {:ok, socket}
    else
      {:ok, socket, layout: false}
    end
  end

  def render(%{live_action: action, params: %{"lang" => lang}} = assigns) do
    ShuttertopWeb.PageView.render("#{action}_#{lang}.html", assigns)
  end

  def render(%{live_action: action} = assigns) do
    ShuttertopWeb.PageView.render("#{action}.html", assigns)
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end
end

defmodule ShuttertopWeb.ContestLive.Index do
  use ShuttertopWeb, :live_page

  alias Shuttertop.Contests

  require Logger

  def render(assigns) do
    ShuttertopWeb.ContestView.render("index.html", assigns)
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(%{
       body_id: "contestsPage",
       app_version: Application.spec(:shuttertop, :vsn)
     })}
  end

  def handle_params(params, _url, socket) do
    {:noreply, fetch(socket, params)}
  end

  defp fetch(%{assigns: %{current_user: current_user}} = socket, params) do
    with {:ok, contest_params} <- contests_params(%{}, params),
         contests <- Contests.get_contests(contest_params, current_user) do
      socket
      |> assign(
        page_title: page_title(params),
        title_bar: gettext("Contest"),
        subtitle_bar: page_title(params),
        params: params,
        contests: contests
      )
    end
  end

  defp page_title(params) do
    t =
      cond do
        params["order"] == "top" ->
          gettext("I migliori contest fotografici")

        !is_nil(params["expired"]) ->
          gettext("Contest fotografici terminati")

        true ->
          gettext("Ultimi contest fotografici inseriti")
      end

    category =
      if is_nil(params["category_id"]) do
        ""
      else
        String.capitalize(translate("category.#{params["category_id"]}")) <> ": "
      end

    String.capitalize(category <> t)
  end
end

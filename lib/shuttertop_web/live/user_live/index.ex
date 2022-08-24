defmodule ShuttertopWeb.UserLive.Index do
  use ShuttertopWeb, :live_page

  alias Shuttertop.{Accounts}

  require Logger

  def render(assigns) do
    ShuttertopWeb.UserView.render("index.html", assigns)
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(%{
       body_id: "usersPage",
       title_bar: gettext("Classifica"),
       app_version: Application.spec(:shuttertop, :vsn)
     })}
  end

  def handle_params(params, _url, socket) do
    {:noreply, fetch(socket, params)}
  end

  def fetch(%{assigns: %{current_user: current_user}} = socket, params) do
    with {:ok, user_params} <- users_params(%{order: :score}, params),
         users = Accounts.get_users(user_params, current_user),
         top_user = Accounts.get_users(%{one: true}, current_user) do
      socket
      |> assign(%{
        user_params: user_params,
        params: params,
        users: users,
        page_title: page_title(params),
        subtitle_bar: page_title(params),
        top_user: top_user
      })
    end
  end

  defp page_title(params) do
    country = get_country_name(params["country_id"])

    t =
      if params["order"] == "trophies" do
        gettext("Classifica %{country} ‧  utenti con più trofei", country: country)
      else
        gettext("Classifica %{country} ‧  utenti con più punti", country: country)
      end

    category =
      if is_nil(params["category_id"]) do
        ""
      else
        String.capitalize(translate("category.#{params["category_id"]}")) <> ": "
      end

    String.capitalize(category <> Gettext.gettext(ShuttertopWeb.Gettext, t))
  end
end

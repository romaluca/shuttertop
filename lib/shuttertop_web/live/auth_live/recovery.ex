defmodule ShuttertopWeb.AuthLive.Recovery do
  use ShuttertopWeb, :live_page

  require Logger

  alias Shuttertop.Accounts
  alias Shuttertop.Repo
  alias Shuttertop.UserFromAuth

  on_mount ShuttertopWeb.InitLiveAssigns

  def render(assigns) do
    ShuttertopWeb.AuthView.render("recovery.html", assigns)
  end

  def mount(%{"token" => token, "email" => email} = _params, _session, socket) do
    a = Accounts.get_authorization_by!(provider: "identity", recovery_token: token, uid: email)

    {:ok,
     socket
     |> assign(%{
       body_id: "recoveryPage",
       authorization: a,
       error: false,
       app_version: Application.spec(:shuttertop, :vsn)
     })}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "save",
        %{
          "authorization" => %{
            "recovery_token" => token,
            "uid" => email,
            "password" => password,
            "password_confirmation" => password_confirmation
          }
        } = _params,
        socket
      ) do
    a = Accounts.get_authorization_by!(provider: "identity", recovery_token: token, uid: email)
    result = UserFromAuth.reset_password(a, password, password_confirmation, Repo)

    socket =
      case result do
        :ok ->
          socket
          |> put_flash(:info, gettext("Password modificata"))
          |> push_redirect(to: Routes.live_path(socket, ShuttertopWeb.AuthLive.Index))

        {_, b} ->
          assign(
            socket,
            authorization: a,
            error: true,
            description: b
          )
      end

    {:noreply, socket}
  end
end

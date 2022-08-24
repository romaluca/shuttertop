defmodule ShuttertopWeb.AuthController do
  require Logger

  @moduledoc """
  Handles the Überauth integration.
  This controller implements the request and callback phases for all providers.
  The actual creation and lookup of users/authorizations is handled by UserFromAuth
  """
  use ShuttertopWeb, :controller

  alias Phoenix.Controller, as: PhoenixController
  alias Shuttertop.UserFromAuth
  alias Shuttertop.Accounts.User
  alias Shuttertop.Accounts
  alias Shuttertop.Guardian.Plug, as: GuardianPlug

  import Phoenix.LiveView.Controller

  plug(Ueberauth)

  def callback(%Plug.Conn{assigns: %{ueberauth_failure: fails}} = conn, _params) do
    current_user = Shuttertop.Guardian.Plug.current_resource(conn)
    Logger.warn("auth fail: #{inspect(fails)} #{inspect(current_user)}")

    conn
    |> put_layout(false)
    |> put_flash(:error, hd(fails.errors).message)
    |> live_render(ShuttertopWeb.AuthLive.Index,
      session: %{
        "current_user" => current_user,
        "error" => hd(fails.errors).message
      }
    )
  end

  def callback(%Plug.Conn{assigns: %{ueberauth_auth: auth}} = conn, params) do
    current_user = GuardianPlug.current_resource(conn)

    case UserFromAuth.get_or_insert(auth, current_user, Repo) do
      {:ok, %User{} = user} ->
        Logger.debug(fn -> "user: #{inspect(user)}" end)

        redirect_url =
          if is_nil(params["redirect"]) || params["redirect"] == "" do
            Routes.live_path(conn, ShuttertopWeb.ActivityLive.Index)
          else
            params["redirect"]
          end

        conn
        # |> GuardianPlug.sign_in(user, %{perms: perms})
        |> GuardianPlug.sign_in(user)
        |> put_session(:locale, user.language)
        |> put_flash(
          :info,
          Gettext.gettext(ShuttertopWeb.Gettext, "Signed in as %{name}", name: user.name)
        )
        |> redirect(to: redirect_url)

      {:error, reason} ->
        Logger.warn("auth fail2: #{inspect(reason)} #{inspect(current_user)}")

        conn
        |> put_layout(false)
        |> live_render(ShuttertopWeb.AuthLive.Index,
          session: %{
            "current_user" => current_user,
            "error" => reason
          }
        )
    end
  end

  # def credentials(conn, _params) do
  #   current_user = Shuttertop.Guardian.Plug.current_resource(conn)
  #   token = Shuttertop.Guardian.Plug.current_token(conn)
  #   user = %{name: current_user.name, email: current_user.email, id: current_user.id}
  #   render(conn, "credentials.json", %{user: user, jwt: token})
  # end

  def logout(conn, %{"token" => token}) do
    current_user = Shuttertop.Guardian.Plug.current_resource(conn)
    Logger.info("------------------LOGOUT---------------")

    if current_user do
      Accounts.delete_device(token, current_user)

      conn
      |> Shuttertop.Guardian.Plug.sign_out()
      |> put_flash(:info, Gettext.gettext(ShuttertopWeb.Gettext, "Signed out"))
      |> redirect(to: "/")
    else
      conn
      |> put_flash(:info, Gettext.gettext(ShuttertopWeb.Gettext, "Not logged in"))
      |> redirect(to: "/")
    end
  end

  def registration_confirm(conn, %{"token" => token, "email" => email} = _params) do
    a = Accounts.get_authorization_by!(provider: "identity", recovery_token: token, uid: email)

    _u =
      a.user
      |> Ecto.Changeset.cast(%{is_confirmed: true}, [:is_confirmed])
      |> Repo.update!()

    conn
    |> put_flash(:info, gettext("Sei dentro! Signed in as %{name}", name: a.user.name))
    |> GuardianPlug.sign_in(a.user)
    # |> GuardianPlug.sign_in(a.user, %{perms: %{default: Shuttertop.Guardian.max()}})
    |> redirect(to: Routes.live_path(conn, ShuttertopWeb.ActivityLive.Index))
  end

  def unauthenticated(conn, _params) do
    conn
    |> PhoenixController.put_flash(:error, "You must be signed in to access that page.")

    # |> PhoenixController.redirect(to: Routes.auth_path(conn, :login, "identity"))
  end
end

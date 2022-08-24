defmodule ShuttertopWeb.AuthLive.PasswordRecovery do
  use ShuttertopWeb, :live_page

  require Logger

  alias Shuttertop.Accounts
  alias Shuttertop.Jobs.UserMailerJob
  alias Shuttertop.Repo

  on_mount ShuttertopWeb.InitLiveAssigns

  def render(assigns) do
    ShuttertopWeb.AuthView.render("password_recovery.html", assigns)
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(%{
       success: nil,
       body_id: "passwordRecoveryPage",
       page_title: gettext("Password recovery"),
       app_version: Application.spec(:shuttertop, :vsn)
     })}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"user" => %{"email" => email}}, socket) do
    a = Accounts.get_authorization_by(provider: "identity", uid: email)

    ret =
      if is_nil(a) do
        false
      else
        {:ok, now} =
          Timex.now()
          |> Timex.format("%Y%m%d%H%M%S", :strftime)

        token = Bcrypt.hash_pwd_salt("#{now}#{email}")

        a
        |> Ecto.Changeset.cast(%{recovery_token: token}, [:recovery_token])
        |> Repo.update!()

        UserMailerJob.enqueue_password_recovery(a.user)

        :ok
      end

    {:noreply, assign(socket, success: ret)}
  end
end

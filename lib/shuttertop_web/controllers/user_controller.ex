defmodule ShuttertopWeb.UserController do
  use ShuttertopWeb, :controller

  require Logger

  alias Shuttertop.{Accounts}
  alias Shuttertop.Accounts.{Authorization, User}
  alias Shuttertop.Jobs.UserMailerJob
  alias Ecto.Changeset

  plug(
    Guardian.Plug.EnsureAuthenticated
    #[handler: ShuttertopWeb.GuardianErrorHandler]
    when action in [:edit]
  )

  action_fallback(ShuttertopWeb.FallbackController)

  def new(conn, %{"modal" => "1"}) do
    changeset = User.changeset(%User{authorizations: [%Authorization{}]})

    conn =
      put_layout(conn, false)
      |> put_root_layout(false)

    render(conn, changeset: changeset, recaptcha: true)
  end

  def new(conn, _params) do
    changeset = User.changeset(%User{authorizations: [%Authorization{}]})
    render(conn, changeset: changeset, recaptcha: true)
  end

  def create(conn, %{"user" => user_params, "g-recaptcha-response" => recaptcha} = _params) do
    {:ok, result} =
      HTTPoison.post(
        "https://www.google.com/recaptcha/api/siteverify",
        {:form, [secret: "6LctTSwUAAAAANEnw9MQSvHVfIt3aIcnhPeFTYib", response: recaptcha]},
        %{"Content-type" => "application/form-data"}
      )

    result =
      result.body
      |> Poison.decode!()

    locale = Gettext.get_locale(ShuttertopWeb.Gettext)
    user_params = Map.put(user_params, "language", locale)

    case Accounts.create_user(user_params, result["success"] != true) do
      {:ok, user} ->
        {:ok, now} =
          Timex.now()
          |> Timex.format("%Y%m%d%H%M%S", :strftime)

        token = Bcrypt.hash_pwd_salt("#{now}#{user.email}")

        Accounts.get_authorization_by(provider: "identity", uid: user.email)
        |> Changeset.cast(%{recovery_token: token}, [:recovery_token])
        |> Repo.update!()

        UserMailerJob.enqueue_registration_confirm(user)

        render(conn, user: user)

      {:error, changeset} ->
        conn
        |> render(
          "new.html",
          current_user: nil,
          recaptcha: true,
          changeset: changeset
        )
    end
  end
end

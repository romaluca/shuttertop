defmodule ShuttertopWeb.Api.InvitationController do
  require Logger

  use ShuttertopWeb, :controller

  alias Shuttertop.{Accounts}
  alias Shuttertop.Jobs.UserMailerJob

  action_fallback(ShuttertopWeb.Api.FallbackController)

  def create(conn, %{"invitation" => %{"email" => email}}) do
    current_user = Shuttertop.Guardian.Plug.current_resource(conn)

    with {:ok, _} <- Accounts.create_invitation(email, current_user) do
      UserMailerJob.enqueue_invitation(current_user, email)

      conn
      |> put_status(:created)
      |> json(nil)
    end
  end
end

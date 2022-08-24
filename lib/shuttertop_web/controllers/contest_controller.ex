defmodule ShuttertopWeb.ContestController do
  use ShuttertopWeb, :controller
  require Logger

  alias Shuttertop.Contests
  alias Shuttertop.{Authorizer}
  alias Shuttertop.Guardian.Plug

  plug(
    Guardian.Plug.EnsureAuthenticated
    #[handler: ShuttertopWeb.GuardianErrorHandler]
    when action in [:new, :create, :edit, :update, :delete]
  )

  action_fallback(ShuttertopWeb.FallbackController)

  def delete(conn, %{"id" => id}) do
    current_user = Plug.current_resource(conn)

    with contest = Contests.get_contest_by!(id: id),
         :ok <- Authorizer.authorize(:delete_contest, current_user, contest),
         {:ok, _contest} <- Contests.delete_contest(contest) do
      conn
      |> put_flash(:info, "Contest deleted successfully.")
      |> redirect(to: Routes.live_path(conn, ShuttertopWeb.ContestLive.Index))
    end
  end
end

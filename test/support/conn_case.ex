defmodule ShuttertopWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ShuttertopWeb.ConnCase

      use Oban.Testing, repo: Shuttertop.Repo

      alias Shuttertop.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias ShuttertopWeb.Router.Helpers, as: Routes
      import Shuttertop.TestHelpers

      # The default endpoint for testing
      @endpoint ShuttertopWeb.Endpoint

      require Logger

      def guardian_login(%Shuttertop.Accounts.User{} = user),
        do: guardian_login(build_conn(), user, :token, [])

      def guardian_login(%Shuttertop.Accounts.User{} = user, token),
        do: guardian_login(build_conn(), user, token, [])

      def guardian_login(%Shuttertop.Accounts.User{} = user, token, opts),
        do: guardian_login(build_conn(), user, token, opts)

      def guardian_login(%Plug.Conn{} = conn, user), do: guardian_login(conn, user, :token, [])

      def guardian_login(%Plug.Conn{} = conn, user, token),
        do: guardian_login(conn, user, token, [])

      def guardian_login(%Plug.Conn{} = conn, user, token, opts) do
        # Gettext.put_locale(ShuttertopWeb.Gettext, "it")
        conn
        |> Plug.Test.init_test_session(locale: "it")
        |> Shuttertop.Guardian.Plug.sign_in(user)

        # conn
        #  |> bypass_through(ShuttertopWeb.Router, [:browser])
        #  |> get("/")
        # |> Shuttertop.Guardian.Plug.sign_in(user, token, opts)
        #  |> Shuttertop.Guardian.Plug.sign_in(user)
        #  |> send_resp(200, "Flush the session yo")
        #  |> recycle()
      end
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Shuttertop.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end

defmodule ShuttertopWeb.Components.ChatTest do
  use ShuttertopWeb.ConnCase

  require Logger

  setup %{conn: conn} = config do
    user1 = insert_user()
    user = insert_user()
    contest = insert_contest(user1)
    photo = insert_photo(user1, contest)

    conn =
      if config[:login] do
        guardian_login(user, :token)
      else
        conn
      end

    {:ok, conn: conn, user: user, contest: contest, photo: photo}
  end
end

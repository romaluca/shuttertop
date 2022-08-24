defmodule Shuttertop.DatabaseSeeder do
  import Ecto.{Query, Changeset}, warn: false
  alias Shuttertop.Repo
  alias Shuttertop.Photos
  alias Shuttertop.{Activities, Posts}
  alias Shuttertop.Accounts.User

  require Logger

  def start() do
    user = Repo.get!(User, 20002)

    for i <- 60000..70000 do
      try do
        Activities.follow_contest(i, :create, user)
      rescue
        _ -> :rescued
      end
    end

    for i <- 10000..20000 do
      try do
        Activities.follow_user(i, :create, user)
      rescue
        _ -> :rescued
      end
    end
  end
end

Shuttertop.DatabaseSeeder.start()

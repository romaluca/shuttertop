# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Shuttertop.Repo.insert!(%Shuttertop.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

defmodule Shuttertop.DatabaseSeeder do
  import Ecto.{Query, Changeset}, warn: false
  alias Shuttertop.Repo
  alias Shuttertop.{Activities, Contests, Follows, Photos, Posts, Votes}
  alias Shuttertop.Accounts.User
  require Shuttertop.Constants

  alias Shuttertop.Constants, as: Const

  require Logger

  @key_user "topm3rda"

  def insert_user(name, index) do
    type = if index == 1, do: Const.user_type_admin(), else: Const.user_type_normal()
    img = Enum.random(1..30)

    user =
      %User{}
      |> User.form_registration_changeset(%{
        name: "#{name}#{index}",
        authorizations: [
          %{"password" => @key_user, "password_confirmation" => @key_user}
        ],
        email: "fake_#{index}@shuttertop.com"
      })
      |> Ecto.Changeset.cast(%{is_confirmed: true, upload: "U_#{img}.jpg", type: type}, [
        :is_confirmed,
        :upload,
        :type
      ])
      |> Repo.insert!()

    c = 2

    for _n <- 1..c do
      try do
        Follows.add(user, random_user())
      rescue
        _ -> :rescued
      end
    end
  end

  defp random_user() do
    users = 2000
    c = Enum.random(1..users)
    Repo.get!(User, c)
  end

  def insert_contest(name, index) do
    contest =
      case Contests.create_contest(
             %{
               "category_id" => 1,
               "description" => "Lorem Ipsum",
               "expiry_at" => Timex.shift(Timex.today(), days: index + 1) |> Timex.to_datetime(),
               "name" => "#{name} #{index}"
             },
             random_user()
           ) do
        {:ok, c} ->
          c

        e ->
          Logger.error(inspect(e))
      end

    for _n <- 1..10 do
      try do
        Follows.add(contest, random_user())
      rescue
        _ -> :rescued
      end
    end

    for n <- 1..2 do
      # try do
      {:ok, %{comment: _comment}} =
        Posts.create_comment(
          contest,
          "Lorem #{n}",
          random_user()
        )
    end

    c = 10

    for _n <- 1..c do
      # try do
      _c = 3
      img = Enum.random(1..104)

      {:ok, photo} =
        Photos.create_photo(
          %{"contest_id" => contest.id, "name" => "photo", "upload" => "P_#{img}.jpg"},
          random_user()
        )

      for n <- 1..1 do
        {:ok, %{comment: _comment}} =
          Posts.create_comment(
            photo.id,
            "photo",
            "Lorem #{n}",
            random_user()
          )
      end

      for _n <- 1..10 do
        try do
          Votes.add(photo, random_user())
        rescue
          _ -> :rescued
        end
      end

      # rescue
      #  _ -> :rescued
      # end
    end
  end
end

users = 2000

for i <- 1..users do
  Shuttertop.DatabaseSeeder.insert_user("Utente test ", i)
end

stream =
  Task.async_stream(
    1..1000,
    fn i ->
      Shuttertop.DatabaseSeeder.insert_contest("Contest test ", i)
    end,
    max_concurrency: 8,
    timeout: :infinity,
    ordered: false
  )

Stream.run(stream)

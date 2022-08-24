defmodule Shuttertop.ContestsTest do
  use Shuttertop.DataCase

  alias Shuttertop.Contests
  alias Shuttertop.Contests.{Contest}
  alias Shuttertop.Accounts.User

  require Logger

  setup do
    user = insert_user()
    contest = insert_contest(user)
    {:ok, user: user, contest: contest}
  end

  test "create contest success", %{user: user} do
    expiry_at1 = Timex.to_datetime(Timex.shift(Timex.today(), days: 2))

    {:ok, contest} =
      Contests.create_contest(%{"expiry_at" => expiry_at1, "name" => "miaoooo"}, user)

    %User{id: id} = contest.user
    assert id == user.id
    assert contest.expiry_at == expiry_at1
  end

  test "update expired contest returns error", %{user: _user1, contest: contest} do
    expiry_at1 = Timex.to_datetime(Timex.shift(Timex.today(), days: 2))
    {:ok, %Contest{} = contest} = Contests.update_contest(contest, %{"expiry_at" => expiry_at1})
    assert contest.expiry_at == expiry_at1

    expiry_at2 = Timex.to_datetime(Timex.shift(Timex.today(), days: -3))
    {:error, _} = Contests.update_contest(contest, %{"expiry_at" => expiry_at2})
    assert contest.expiry_at == expiry_at1

    contest2 =
      contest
      |> Ecto.Changeset.change(expiry_at: expiry_at2)
      |> Repo.update!()

    {:error, _} = Contests.update_contest(contest2, %{"expiry_at" => expiry_at1})
  end
end

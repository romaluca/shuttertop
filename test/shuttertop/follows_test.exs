defmodule Shuttertop.FollowsTest do
  use Shuttertop.DataCase
  alias Shuttertop.{Follows, Contests}
  alias Shuttertop.Contests.Contest

  require Logger

  setup do
    user = insert_user()
    user2 = insert_user()
    contest = insert_contest(user)

    {:ok, user: user, user2: user2, contest: contest}
  end

  test "follow contest ok", %{user: user1, contest: contest} do
    assert !Follows.is_following(contest)
    ret = Follows.add(contest, user1)
    {:ok, %Contest{} = contest} = ret
    assert Follows.is_following(contest)
  end

  test "refollow contest error", %{user: user1, contest: contest} do
    {:ok, contest} = Follows.add(contest, user1)
    ret = Follows.add(contest, user1)
    {:error, _, _, _} = ret
    assert Follows.is_following(contest)
  end

  test "unfollow contest ok", %{user: user1, contest: contest} do
    Follows.add(contest, user1)
    contest = Contests.get_contest_by!([id: contest.id], user1)
    assert Follows.is_following(contest)
    ret = Follows.remove(contest, user1)
    {:ok, %Contest{} = contest} = ret
    assert !Follows.is_following(contest)
  end

  test "reunfollow contest error", %{user: user1, contest: contest} do
    {:error, "follow"} = Follows.remove(contest, user1)
    contest = Contests.get_contest_by!([id: contest.id], user1)
    assert !Follows.is_following(contest)
  end
end

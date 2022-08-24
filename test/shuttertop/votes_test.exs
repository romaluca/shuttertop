defmodule Shuttertop.VotesTest do
  use Shuttertop.DataCase
  alias Shuttertop.Photos.Photo
  alias Shuttertop.{Photos, Votes}

  require Logger

  setup do
    user = insert_user()
    contest = insert_contest(user)
    photo = insert_photo(user, contest)

    {:ok, user: user, contest: contest, photo: photo}
  end

  test "vote photo ok", %{user: user1, photo: photo} do
    assert !Votes.is_voted(photo, user1)
    assert photo.votes_count == 0
    ret = Votes.add(photo, user1)
    {:ok, %Photo{} = photo} = ret
    assert Votes.is_voted(photo, user1)
    assert photo.votes_count == 1
  end

  test "revote photo error", %{user: user1, photo: photo} do
    {:ok, photo} = Votes.add(photo, user1)
    ret = Votes.add(photo, user1)
    {:error, %{status: 1}} = ret
    assert Votes.is_voted(photo, user1)
  end

  test "remove vote photo ok", %{user: user1, photo: photo} do
    {:ok, photo} = Votes.add(photo, user1)
    assert photo.votes_count == 1
    ret = Votes.remove(photo, user1)
    {:ok, %Photo{} = photo} = ret
    assert photo.votes_count == 0
    assert !Votes.is_voted(photo, user1)
  end

  test "remove vote photo error", %{user: user1, photo: photo} do
    {:ok, photo} = Votes.add(photo, user1)
    ret = Votes.remove(photo, user1)
    {:ok, %Photo{} = photo} = ret
    ret = Votes.remove(photo, user1)
    {:error, %{status: 1}} = ret
    assert !Votes.is_voted(photo, user1)
  end

  test "Random Vote photo success", %{photo: photo} do
    assert photo.votes_count == 0
    insert_user(%{email: "fake_1@shuttertop.com"})
    {:ok} = Votes.vote_random(%{"photo_id" => photo.id, "sleep" => 1})
    photo = Photos.get_photo!(photo.id)
    assert photo.votes_count == 1
  end

  test "Random Vote contest success", %{contest: contest} do
    insert_user(%{email: "fake_1@shuttertop.com"})
    {:ok} = Votes.vote_random(%{"contest_id" => contest.id, "sleep" => 1})
  end

  test "Random Vote success", %{} do
    insert_user(%{email: "fake_1@shuttertop.com"})
    {:ok} = Votes.vote_random(%{"sleep" => 1})
  end
end

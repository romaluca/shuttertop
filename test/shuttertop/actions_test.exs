defmodule Shuttertop.ActionsTest do
  use Shuttertop.DataCase
  alias Shuttertop.{Photos, Votes}
  alias Shuttertop.Photos.Photo

  require Logger

  setup do
    user = insert_user()
    contest = insert_contest(user)
    photo = insert_photo(user, contest)

    {:ok, user: user, contest: contest, photo: photo}
  end

  test "vote ok", %{user: user1, contest: _contest, photo: photo} do
    user2 = insert_user()
    user3 = insert_user()
    {:ok, photo} = Votes.add(photo, user1)
    {:ok, photo} = Votes.remove(photo, user1)
    {:ok, photo} = Votes.add(photo, user2)
    {:ok, photo} = Votes.add(photo, user3)
    {:error, _data} = Votes.add(photo, user2)
    %Photo{votes_count: score} = Photos.get_photo!(photo.id)
    assert score == 2
  end
end

defmodule Shuttertop.PostsTest do
  use Shuttertop.DataCase
  alias Shuttertop.Posts

  require Logger

  setup do
    user = insert_user()
    contest = insert_contest(user)
    photo = insert_photo(user, contest)
    {:ok, user: user, contest: contest, photo: photo}
  end

  test "topic create with valid comment", %{user: user, contest: contest, photo: _photo} do
    {:ok, ret} = Posts.create_comment(contest, "caio", user)
    assert !is_nil(ret)
  end
end

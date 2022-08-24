defmodule Shuttertop.CommentTest do
  use Shuttertop.DataCase

  require Logger

  alias Shuttertop.Posts.{Comment}

  @valid_attrs %{body: "some content"}
  # @invalid_attrs %{}

  test "changeset with valid attributes" do
    user = insert_user()
    user2 = insert_user()
    topic = insert_topic(%{user_id: user.id, user_to_id: user2.id}, user2.id)
    changeset = Comment.changeset(%Comment{user_id: user.id, topic_id: topic.id}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid topic" do
    user = insert_user()
    changeset = Comment.changeset(%Comment{user_id: user.id}, @valid_attrs)
    refute changeset.valid?
  end
end

defmodule Shuttertop.TopicTest do
  use Shuttertop.DataCase

  alias Shuttertop.Posts.Topic

  @valid_attrs %{}
  # @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Topic.changeset(%Topic{}, @valid_attrs)
    assert changeset.valid?
  end

  # test "changeset with invalid attributes" do
  #   changeset = Topic.changeset(%Topic{}, @invalid_attrs)
  #   refute changeset.valid?
  # end
end

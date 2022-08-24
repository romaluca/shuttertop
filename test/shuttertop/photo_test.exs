defmodule Shuttertop.PhotoTest do
  use Shuttertop.DataCase

  require Logger

  # alias Shuttertop.Photos
  alias Shuttertop.Photos.Photo

  @valid_attrs %{
    "comments_count" => 42,
    "is_visibile" => true,
    "name" => "some content",
    "position" => 42,
    "upload" => "some content",
    "votes_count" => 42,
    "contest_id" => 1
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Photo.create_changeset(%Photo{user_id: 1}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Photo.create_changeset(%Photo{}, @invalid_attrs)
    refute changeset.valid?
  end
end

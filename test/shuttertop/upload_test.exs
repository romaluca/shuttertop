defmodule Shuttertop.UploadTest do
  use Shuttertop.DataCase

  alias Shuttertop.Uploads.Upload

  @valid_attrs %{
    contest_id: 42,
    expiry_at: Timex.to_datetime(Timex.shift(Timex.today(), days: -605)),
    name: "some name",
    type: 42
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    user = insert_user()
    changeset = Upload.changeset(%Upload{user_id: user.id}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Upload.changeset(%Upload{}, @invalid_attrs)
    refute changeset.valid?
  end
end

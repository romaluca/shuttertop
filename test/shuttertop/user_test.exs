defmodule Shuttertop.UserTest do
  use Shuttertop.DataCase

  alias Shuttertop.Accounts.User

  @valid_attrs %{
    name: "user prova",
    authorizations: [
      %{"password" => "supersecret", "password_confirmation" => "supersecret"}
    ],
    email: "mail3232@shuttertop.com"
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end

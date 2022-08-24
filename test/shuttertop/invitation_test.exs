defmodule Shuttertop.InvitationTest do
  use Shuttertop.DataCase

  require Logger
  require Shuttertop.Constants

  alias Shuttertop.Accounts
  alias Shuttertop.Accounts.{Invitation, User}
  alias Shuttertop.Activities
  alias Shuttertop.Activities.Activity
  alias Shuttertop.Constants, as: Const

  @email "testinvitation@shuttertop.com"

  @valid_attrs %{
    email_hash: Accounts.get_hashed_email(@email)
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    user = insert_user()
    changeset = Invitation.changeset(%Invitation{user_id: user.id}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    user = insert_user()
    changeset = Invitation.changeset(%Invitation{user_id: user.id}, @invalid_attrs)
    refute changeset.valid?
  end

  test "test delete invitations after user signed up" do
    user = insert_user()
    assert Repo.one(from(p in Invitation, select: count(p.id))) == 0
    {:ok, _invitation} = Accounts.create_invitation(@email, user)
    assert Repo.one(from(p in Invitation, select: count(p.id))) == 1
    user2 = insert_user(%{email: @email})
    assert Repo.one(from(p in Invitation, select: count(p.id))) == 1
    task = Activities.check_invitations_on_registration(user2)
    Task.await(task)
    assert Repo.one(from(p in Invitation, select: count(p.id))) == 0

    Repo.one!(
      from(a in Activity,
        where:
          a.user_id == ^user2.id and
            a.type == ^Const.action_friend_signed() and
            a.user_to_id == ^user.id
      )
    )

    Repo.one!(from(u in User, where: u.id == ^user.id and u.notify_count == 1))
  end
end

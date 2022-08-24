defmodule Shuttertop.AccountsTest do
  use Shuttertop.DataCase

  alias Shuttertop.Accounts
  alias Shuttertop.Accounts.User

  require Logger

  setup do
    user = insert_user()

    {:ok, user: user}
  end

  test "block and unblock user returns ok", %{user: user1} do
    users = Accounts.get_users(%{blocked: "1"}, user1)
    assert users.total_entries == 0
    user2 = insert_user()
    {:error} = Accounts.delete_blocked_user(user2, user1)
    {:error, _} = Accounts.create_blocked_user(%User{id: 80}, user1)
    user2 = Accounts.get_user_by([id: user2.id], user1)
    {:ok, _} = Accounts.create_blocked_user(user2, user1)
    users = Accounts.get_users(%{blocked: "1"}, user1)
    assert users.total_entries == 1
    {:error, _} = Accounts.create_blocked_user(user2, user1)
    {:ok} = Accounts.delete_blocked_user(user2, user1)
    users = Accounts.get_users(%{blocked: "1"}, user1)
    assert users.total_entries == 0
  end
end

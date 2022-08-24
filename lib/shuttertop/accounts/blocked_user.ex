defmodule Shuttertop.Accounts.BlockedUser do
  @moduledoc false
  use TypedEctoSchema
  import Ecto.Changeset

  require Logger

  @primary_key false
  typed_schema "blocked_users" do
    belongs_to(:user, Shuttertop.Accounts.User, foreign_key: :user_id, primary_key: true)
    belongs_to(:user_to, Shuttertop.Accounts.User, foreign_key: :user_to_id, primary_key: true)

    timestamps()
  end

  @spec changeset(t) :: Ecto.Changeset.t()
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :user_to_id])
    |> validate_required([:user_id, :user_to_id])
    |> foreign_key_constraint(:user_to_id)
    |> unique_constraint([:user_id, :user_to_id], name: :blocked_users_pkey)
  end
end

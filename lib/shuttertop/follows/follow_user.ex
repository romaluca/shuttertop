defmodule Shuttertop.Follows.FollowUser do
  @moduledoc false

  use TypedEctoSchema
  import Ecto.Changeset

  require Shuttertop.Constants

  alias Shuttertop.Accounts.User
  alias Shuttertop.Constants, as: Const

  typed_schema "activities" do
    field(:points, :integer, default: 0)
    field(:type, :integer, default: Const.action_follow_user())
    belongs_to(:user_to, User)
    belongs_to(:user, User)

    timestamps()
  end

  @spec changeset(__MODULE__.t()) :: Ecto.Changeset.t()
  def changeset(struct) do
    struct
    |> cast(%{type: Const.action_follow_user(), points: Const.points_follow_user()}, [
      :type,
      :points
    ])
    |> validate_required([:user_id, :user_to_id])
    |> unique_constraint(:user_to_id, name: :user_follow_activities_index)
    |> foreign_key_constraint(:user_to_id)
  end
end

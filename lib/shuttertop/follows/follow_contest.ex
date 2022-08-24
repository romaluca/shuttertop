defmodule Shuttertop.Follows.FollowContest do
  @moduledoc false

  use TypedEctoSchema
  import Ecto.Changeset

  require Shuttertop.Constants

  alias Shuttertop.Accounts.User
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Constants, as: Const

  typed_schema "activities" do
    field(:points, :integer, default: 0)
    field(:type, :integer, default: Const.action_follow_contest())
    belongs_to(:user_to, User)
    belongs_to(:contest, Contest)
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(struct) do
    struct
    |> cast(%{type: Const.action_follow_contest(), points: Const.points_follow_contest()}, [
      :type,
      :points
    ])
    |> validate_required([:user_id, :user_to_id, :contest_id])
    |> unique_constraint(:contest_id, name: :contest_follow_activities_index)
    |> foreign_key_constraint(:contest_id)
  end
end

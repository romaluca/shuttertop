defmodule Shuttertop.Follows.FollowPhoto do
  @moduledoc false

  use TypedEctoSchema
  import Ecto.Changeset

  require Shuttertop.Constants

  alias Shuttertop.Accounts.User
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Constants, as: Const

  typed_schema "activities" do
    field(:points, :integer, default: 0)
    field(:type, :integer, default: Const.action_follow_photo())
    belongs_to(:user_to, User)
    belongs_to(:photo, Photo)
    belongs_to(:contest, Contest)
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(struct) do
    struct
    |> cast(%{type: Const.action_follow_photo(), points: Const.points_follow_photo()}, [
      :type,
      :points
    ])
  end
end

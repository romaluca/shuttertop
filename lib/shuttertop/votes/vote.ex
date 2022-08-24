defmodule Shuttertop.Votes.Vote do
  @moduledoc false

  use TypedEctoSchema
  import Ecto.Changeset

  require Shuttertop.Constants

  alias Shuttertop.Accounts.User
  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo

  typed_schema "activities" do
    field(:points, :integer, default: 0)
    field(:type, :integer, default: Const.action_vote())
    belongs_to(:user_to, User)
    belongs_to(:photo, Photo)
    belongs_to(:contest, Contest)
    belongs_to(:user, User)

    timestamps()
  end

  @spec changeset(__MODULE__.t()) :: Ecto.Changeset.t()
  def changeset(struct) do
    struct
    |> cast(%{type: Const.action_vote(), points: Const.points_vote()}, [:type, :points])
    |> validate_required([:user_id, :user_to_id, :contest_id, :photo_id])
    |> unique_constraint(:photo_id, name: :vote_activities_index)
    |> foreign_key_constraint(:photo_id)
  end
end

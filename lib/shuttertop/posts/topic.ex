defmodule Shuttertop.Posts.Topic do
  @moduledoc false
  use TypedEctoSchema
  import Ecto.Changeset

  typed_schema "topics" do
    belongs_to(:user, Shuttertop.Accounts.User, foreign_key: :user_id)
    belongs_to(:user_to, Shuttertop.Accounts.User, foreign_key: :user_to_id)
    belongs_to(:photo, Shuttertop.Photos.Photo)
    belongs_to(:contest, Shuttertop.Contests.Contest)
    belongs_to(:last_comment, Shuttertop.Posts.Comment, foreign_key: :last_comment_id)
    has_many(:topics_users, Shuttertop.Posts.TopicUser, on_delete: :delete_all)

    many_to_many(:members, Shuttertop.Accounts.User,
      join_through: "topics_users",
      on_delete: :delete_all
    )
  end

  @spec changeset(t()) :: Ecto.Changeset.t()
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:user_to_id, :user_id, :photo_id, :contest_id, :last_comment_id])
    |> unique_constraint(:topic, name: :topic_all_index)
  end
end

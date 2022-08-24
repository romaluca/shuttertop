defmodule Shuttertop.Posts.TopicUser do
  @moduledoc false
  use TypedEctoSchema
  import Ecto.Changeset

  typed_schema "topics_users" do
    belongs_to(:user, Shuttertop.Accounts.User, foreign_key: :user_id)
    belongs_to(:topic, Shuttertop.Posts.Topic)
    field(:last_read_at, :utc_datetime)
  end

  @spec changeset(t()) :: Ecto.Changeset.t()
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :topic_id, :last_read_at])
    |> validate_required([:user_id, :topic_id])
  end
end

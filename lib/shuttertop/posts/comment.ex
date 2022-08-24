defmodule Shuttertop.Posts.Comment do
  @moduledoc false

  use TypedEctoSchema
  import Ecto.Changeset
  alias Shuttertop.Accounts.User
  alias Shuttertop.Posts.Topic

  typed_schema "comments" do
    field(:body, :string)
    belongs_to(:user, User)
    belongs_to(:topic, Topic)

    timestamps()
  end

  @spec changeset(t()) :: Ecto.Changeset.t()
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body, :topic_id])
    |> validate_required([:body, :topic_id])
  end
end

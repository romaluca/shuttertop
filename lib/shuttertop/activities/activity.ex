defmodule Shuttertop.Activities.Activity do
  @moduledoc false

  use TypedEctoSchema
  import Ecto.Changeset

  alias Shuttertop.Accounts.User
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo

  typed_schema "activities" do
    field(:points, :integer, default: 0)
    field(:type, :integer)
    belongs_to(:user_to, User)
    belongs_to(:photo, Photo)
    belongs_to(:contest, Contest)
    belongs_to(:user, User)

    timestamps()
  end

  @spec changeset(:basic, t()) :: Ecto.Changeset.t()
  def changeset(:basic, struct) do
    struct
    |> cast(%{}, [])
  end
end

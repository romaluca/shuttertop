defmodule Shuttertop.Photos.Photo do
  @moduledoc false

  use TypedEctoSchema
  import Ecto.Changeset

  alias Shuttertop.Accounts.User
  alias Shuttertop.Activities.Activity
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Posts.Topic
  alias Shuttertop.Events.Event

  typed_schema "photos" do
    field(:name, :string, null: true)
    field(:slug, :string, null: false)
    field(:position, :integer, null: false)
    field(:is_visibile, :boolean, default: false)
    field(:upload, :string, null: false)
    field(:votes_count, :integer, default: 0)
    field(:comments_count, :integer, default: 0)
    field(:voted, :boolean, default: false, virtual: true)

    field(:meta, :map, null: true)

    field(:model, :string, null: true)
    field(:f_number, :float, null: true)
    field(:focal_length, :string, null: true)
    field(:photographic_sensitivity, :integer, null: true)
    field(:exposure_time, :float, null: true)
    field(:lat, :float, null: true)
    field(:lng, :float, null: true)
    field(:width, :integer, null: true)
    field(:height, :integer, null: true)

    belongs_to(:contest, Contest)
    belongs_to(:user, User)
    belongs_to(:topic, Topic)

    has_one(:win, Contest, foreign_key: :winner_id, on_delete: :delete_all)

    has_many(:activities, Activity, on_delete: :delete_all)
    has_many(:events, Event, on_delete: :delete_all)

    timestamps()
  end

  @spec fields_basic() :: [atom]
  def fields_basic(),
    do: [
      :id,
      :name,
      :slug,
      :upload,
      :votes_count,
      :comments_count,
      :width,
      :height,
      :position,
      :user_id,
      :contest_id
    ]

  @spec create_changeset(t()) :: Ecto.Changeset.t()
  @spec create_changeset(t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, [
      :upload,
      :contest_id,
      :name,
      :meta,
      :model,
      :f_number,
      :focal_length,
      :photographic_sensitivity,
      :exposure_time,
      :lat,
      :lng,
      :width,
      :height
    ])
    |> validate_required([:upload, :contest_id])
    # |> unique_constraint(:contest_id_user_id)
    |> assoc_constraint(:contest)
  end

  @spec changeset(t) :: Ecto.Changeset.t()
  @spec changeset(t, map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :is_visibile])
    |> validate_length(:name, max: 100)
  end

  @spec new_changeset() :: Ecto.Changeset.t()
  @spec new_changeset(integer()) :: Ecto.Changeset.t()
  def new_changeset() do
    %__MODULE__{}
    |> cast(%{}, [])
  end

  def new_changeset(contest_id) do
    %__MODULE__{}
    |> cast(%{contest_id: contest_id}, [:contest_id])
  end
end

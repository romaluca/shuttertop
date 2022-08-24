defmodule Shuttertop.Events.Event do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo

  typed_schema "events" do
    field(:type, :integer)
    field(:week, :integer)
    field(:year, :integer)

    belongs_to(:contest, Contest)
    belongs_to(:photo, Photo)
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = agenda, attrs \\ %{}) do
    agenda
    |> cast(attrs, [:type, :week, :year, :contest_id, :photo_id])
    |> unique_constraint([:type, :week, :year])
    |> validate_required([:type])
  end

  @spec get_week_year() :: {:ok, Integer.t(), Integer.t()}
  def get_week_year() do
    date = DateTime.utc_now()
    year = date.year
    week = floor((Date.day_of_year(date) - Date.day_of_week(date) + 10) / 7)

    {:ok, week, year}
  end
end

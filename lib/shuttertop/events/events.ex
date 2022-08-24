defmodule Shuttertop.Events do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  require Logger
  require Shuttertop.Constants

  alias Shuttertop.{
    Repo
  }

  alias Shuttertop.Events.Event

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  def get_events do
    {:ok, week, year} = Event.get_week_year()

    query =
      from(e in Event,
        preload: [:contest],
        where: e.week == ^week and e.year == ^year
      )

    Repo.all(query)
  end

  @spec delete_event(Integer.t()) :: any
  def delete_event(id) do
    Event
    |> Repo.get!(id)
    |> Repo.delete()
  end
end

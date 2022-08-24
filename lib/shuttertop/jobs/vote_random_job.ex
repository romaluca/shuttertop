defmodule Shuttertop.Jobs.VoteRandomJob do
  use Oban.Worker, queue: :background, max_attempts: 5

  alias Shuttertop.Votes

  @impl Oban.Worker
  def perform(_) do
    Votes.vote_random()

    :ok
  end
end

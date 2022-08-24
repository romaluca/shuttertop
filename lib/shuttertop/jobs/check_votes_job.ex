defmodule Shuttertop.Jobs.CheckVotesJob do
  use Oban.Worker, queue: :background, max_attempts: 5

  alias Shuttertop.Votes

  @impl Oban.Worker
  def perform(_) do
    Votes.check_votes()

    :ok
  end
end

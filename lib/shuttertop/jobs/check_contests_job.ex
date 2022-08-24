defmodule Shuttertop.Jobs.CheckContestsJob do
  use Oban.Worker, queue: :background, max_attempts: 5

  alias Shuttertop.Contests

  @impl Oban.Worker
  def perform(_) do
    Contests.check_contests()

    :ok
  end
end

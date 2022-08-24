defmodule Shuttertop.Jobs.CheckUploadsJob do
  use Oban.Worker, queue: :background, max_attempts: 5

  alias Shuttertop.Uploads

  @impl Oban.Worker
  def perform(_) do
    Uploads.check_uploads()

    :ok
  end
end

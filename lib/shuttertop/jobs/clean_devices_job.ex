defmodule Shuttertop.Jobs.CleanDevicesJob do
  use Oban.Worker, queue: :background, max_attempts: 5

  alias Shuttertop.Accounts

  @impl Oban.Worker
  def perform(_) do
    Accounts.clean_devices()

    :ok
  end
end

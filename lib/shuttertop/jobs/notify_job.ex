defmodule Shuttertop.Jobs.NotifyJob do
  use Oban.Worker, queue: :background, max_attempts: 5

  alias Shuttertop.FCM.PusherHttp

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => type, "id" => id, "user_ids" => user_ids}}) do
    PusherHttp.push(:"#{type}", id, user_ids)

    :ok
  end

  def perform(%Oban.Job{args: %{"type" => type, "id" => id}}) do
    PusherHttp.push(:"#{type}", id, nil)

    :ok
  end

  @spec enqueue(:activity | :comment | :event, Integer.t(), [Integer.t()]) :: Oban.Job.t()
  def enqueue(type, id, user_ids)

  def enqueue(type, id, user_ids) when type in [:comment, :event, :activity] do
    %{"type" => type, "id" => id, "user_ids" => user_ids}
    |> Shuttertop.Jobs.NotifyJob.new()
    |> Oban.insert!()
  end

  @spec enqueue(:activity | :comment | :event, Integer.t()) :: Oban.Job.t()
  def enqueue(type, id)

  def enqueue(type, id) when type in [:comment, :event, :activity] do
    %{"type" => type, "id" => id}
    |> Shuttertop.Jobs.NotifyJob.new()
    |> Oban.insert!()
  end
end

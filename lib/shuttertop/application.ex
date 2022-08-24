defmodule Shuttertop.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    :ets.new(:app_configs, [:set, :public, :named_table])
    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      Shuttertop.Repo,
      ShuttertopWeb.Telemetry,
      {Phoenix.PubSub, name: Shuttertop.PubSub},
      ShuttertopWeb.Endpoint,
      {Oban, oban_config()}
    ]

    opts = [strategy: :one_for_one, name: Shuttertop.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    ShuttertopWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def oban_config do
    Application.get_env(:shuttertop, Oban)
  end
end

import Config

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :shuttertop, Shuttertop.Repo,
  database: "shuttertop_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :shuttertop, :environment, :test

config :shuttertop, Oban,
  plugins: false,
  queues: false

config :shuttertop, Shuttertop.Mailer, adapter: Swoosh.Adapters.Test

config :shuttertop, ShuttertopWeb.Endpoint,
  http: [port: 4001],
  server: false,
  facebook_test_token: System.get_env("facebook_test_token")

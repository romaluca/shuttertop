import Config

config :shuttertop, ShuttertopWeb.Endpoint,
  load_from_system_env: true,
  http: [port: {:system, "PORT"}],
  url: [host: "shuttertop.com", port: {:system, "PORT"}, scheme: "https"],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Mix.Project.config()[:version]

config :logger, level: :info

config :shuttertop, Shuttertop.Repo, database: "shuttertop_prod"

config :logger, Sentry.LoggerBackend,
  capture_log_messages: true,
  level: :warn,
  excluded_domains: []

config :shuttertop, :environment, :prod

config :phoenix, :serve_endpoints, true

config :shuttertop, Shuttertop.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: "localhost",
  port: 25,
  tls: :always,
  # auth: :always,
  # can be `true`
  ssl: false

# no_mx_lookup: false
# retries: 1
# tls: :if_available, # can be `:always` or `:never`
# server: "localhost",

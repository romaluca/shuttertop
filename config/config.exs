# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :esbuild,
  version: "0.12.18",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :dart_sass,
  version: "1.36.0",
  default: [
    args: [
      "--load-path=./node_modules",
      "css/app.scss",
      "../priv/static/assets/app.css"
    ],
    cd: Path.expand("../assets", __DIR__)
  ]

# General application configuration
config :shuttertop, ecto_repos: [Shuttertop.Repo]

config :shuttertop, ShuttertopWeb.Gettext, locales: ~w(en es pt it), default_locale: "it"

# Configures the endpoint
config :shuttertop, ShuttertopWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: ShuttertopWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: Shuttertop.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger,
  backends: [:console, Sentry.LoggerBackend]

config :logger, Sentry.LoggerBackend,
  level: :warn,
  capture_log_messages: true

config :phoenix, :json_library, Jason

config :ueberauth, Ueberauth,
  providers: [
    facebook:
      {Ueberauth.Strategy.Facebook,
       [
         profile_fields: "email, name",
         callback_url:
           "#{if Mix.env() == :prod, do: "https://shuttertop.com", else: "http://localhost:8080"}/auth/facebook/callback"
       ]},
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]},
    identity: {Ueberauth.Strategy.Identity, [callback_methods: ["POST"]]},
    apple: {Ueberauth.Strategy.Apple, [default_scope: "name email", callback_methods: ["POST"]]}
  ]

config :shuttertop, Shuttertop.Guardian,
  issuer: "shuttertop",
  ttl: {30, :days},
  verify_issuer: true #,
  #error_handler: Shuttertop.AuthErrorHandler

config :sentry,
  dsn: "https://c1ce2be375594c0a89a74de041f9e7df@sentry.io/1272256",
  environment_name: Mix.env(),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: "production"
  },
  included_environments: [:prod]

config :shuttertop, Oban,
  repo: Shuttertop.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {Oban.Plugins.Cron,
     crontab: [
       {"*/15 * * * *", Shuttertop.Jobs.CheckContestsJob},
       {"*/5 * * * *", Shuttertop.Jobs.CheckUploadsJob},
       {"13 8,11,15,18,21 * * *", Shuttertop.Jobs.VoteRandomJob},
       {"0 0 * * *", Shuttertop.Jobs.CleanDevicesJob},
       {"0 3 * * *", Shuttertop.Jobs.CheckVotesJob}
     ]}
  ],
  queues: [mails: 10, background: 10, media: 20]

# timezone: "Europe/Berlin",

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

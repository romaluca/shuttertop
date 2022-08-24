import Config

config :shuttertop, ShuttertopWeb.Endpoint,
  http: [port: System.get_env("PORT") || 8000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    sass: {
      DartSass,
      :install_and_run,
      [:default, ~w(--embed-source-map --source-map-urls=absolute --watch)]
    }
  ],
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/shuttertop_web/templates/.*(eex)$},
      ~r{lib/shuttertop_web/live/.*(ex)$},
      ~r{lib/shuttertop_web/views/.*(ex)$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

config :logger, level: :debug

config :phoenix, :stacktrace_depth, 20

# Configure your database
config :shuttertop, Shuttertop.Repo, database: "shuttertop_dev"

config :shuttertop, Shuttertop.Mailer, adapter: Swoosh.Adapters.Local
config :swoosh, serve_mailbox: true, preview_port: 8081

config :shuttertop, :environment, :dev

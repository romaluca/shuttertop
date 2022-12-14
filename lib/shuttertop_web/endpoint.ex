defmodule ShuttertopWeb.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :shuttertop

  socket("/socket", ShuttertopWeb.UserSocket)

  @session_options [
    store: :cookie,
    key: "_shuttertop_key",
    signing_salt: "C1/R5dzI"
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    at: "/",
    from: :shuttertop,
    gzip: false,
    only:
      ~w(assets .well-known fonts images ads.txt app-ads.txt robots.txt firebase-messaging-sw.js android-chrome-192x192.png android-chrome-512x512.png apple-touch-icon.png favicon-16x16.png favicon-32x32.png favicon.png favicon.ico logo.png site.webmanifest)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :shuttertop
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug(Plug.RequestId)
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(
    Plug.Session,
    @session_options
  )

  plug(CORSPlug,
    origin: [
      "http://localhost:18080",
      "https://appleid.apple.com"
    ]
  )

  plug(ShuttertopWeb.Router)

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.get_env("PORT") || raise "expected the PORT environment variabletobe set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end
end

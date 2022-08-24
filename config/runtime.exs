import Config

# In this file, we keep production configuration that
# you likely want to automate and keep it away from
# your version control system.
#
# You should document the content of this
# file or create a script for recreating it, since it's
# kept out of version control and might be hard to recover
# or recreate for your teammates (or you later on).
config :shuttertop, ShuttertopWeb.Endpoint,
  secret_key_base: System.get_env("secret_key_base"),
  google_key_api: System.get_env("google_key_api"),
  live_view: [signing_salt: System.get_env("live_view_secret")]

# Configure your database
config :shuttertop, Shuttertop.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: System.get_env("POSTGRES_USERNAME"),
  password: System.get_env("POSTGRES_PASSWORD"),
  hostname: System.get_env("POSTGRES_HOST"),
  pool_size: 20

config :shuttertop, Shuttertop.Guardian, secret_key: System.get_env("guardian_secret")

config :ueberauth, Ueberauth.Strategy.Facebook.OAuth,
  client_id: System.get_env("fb_client_id"),
  client_secret: System.get_env("fb_client_secret"),
  token_url: "/v2.8/oauth/access_token"

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("google_client_id"),
  client_secret: System.get_env("google_client_secret")

config :ueberauth, Ueberauth.Strategy.Apple.OAuth,
  client_id: System.get_env("apple_client_id"),
  client_secret: {Shuttertop.SocialAuth, :apple_secret},
  client_id_native: System.get_env("apple_client_id_native")

config :ex_aws,
  access_key_id: System.get_env("aws_access_key_id"),
  secret_access_key: System.get_env("aws_secret_access_key"),
  region: "eu-west-1",
  s3: [
    scheme: "https://",
    region: "eu-west-1"
  ]

config :shuttertop, Shuttertop.Mailer,
  username: System.get_env("smtp_username"),
  password: System.get_env("smtp_password")

config :fcmex,
  server_key: System.get_env("fcmex_server_key")

config :recaptcha,
  public_key: System.get_env("recaptcha_public_key"),
  secret: System.get_env("recaptcha_private_key")

config :shuttertop,
  api_key: System.get_env("shuttertop_api_key"),
  min_android_version: System.get_env("min_android_version"),
  min_ios_version: System.get_env("min_ios_version"),
  fcm_server_key: System.get_env("fcmex_server_key"),
  apple_key_id: System.get_env("apple_key_id"),
  apple_team_id: System.get_env("apple_team_id"),
  apple_private_key: System.get_env("apple_private_key")

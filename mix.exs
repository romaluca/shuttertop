defmodule Shuttertop.Mixfile do
  use Mix.Project

  def project do
    [
      app: :shuttertop,
      version: "1.0.0+#{Calendar.strftime(DateTime.utc_now(), "%y%m%d%H%M%S")}",
      elixir: "~> 1.13.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: true],
      compilers: [:gettext] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        shuttertop: [
          include_executables_for: [:unix],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Shuttertop.Application, []},
      extra_applications: [
        :sentry,
        :logger,
        :runtime_tools,
        :os_mon,
        :oauth2,
        :ueberauth_facebook,
        :ueberauth_google,
        :ueberauth_apple,
        :comeonin,
        :tzdata,
        :ex_aws,
        :hackney,
        :httpoison,
        :poison,
        :phoenix_html_simplified_helpers,
        :recaptcha
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 3.0.0"},
      {:comeonin, "~> 5.3.3"},
      # {:cachex, "~> 3.4"},
      {:cors_plug, "~> 2.0.3"},
      {:countries, "~> 1.6"},
      {:credo, "~> 1.6.3", only: [:dev, :test], runtime: false},
      {:dart_sass, "~> 0.4", runtime: Mix.env() == :dev},
      {:dialyxir, "~> 1.1.0", only: [:dev], runtime: false},
      {:ecto_psql_extras, "~> 0.7.4"},
      {:ecto_sql, "~> 3.7.2"},
      {:esbuild, "~> 0.4.0", runtime: Mix.env() == :dev},
      {:ex_aws, "~> 2.2.10"},
      {:ex_aws_s3, "~> 2.3.2"},
      {:fcmex, "~> 0.5.0"},
      {:hackney, "~> 1.18.0"},
      {:httpoison, "~> 1.8.0"},
      {:ja_serializer, "~> 0.16"},
      {:jason, "~> 1.3.0"},
      {:jose, "~> 1.11.2"},
      {:floki, ">= 0.30.0", only: :test},
      {:gen_smtp, "~> 1.1.0"},
      {:gen_stage, "~> 1.1"},
      {:gettext, "~> 0.19.1"},
      {:guardian, "~> 2.2.1"},
      {:guardian_phoenix, "~> 2.0.1"},
      {:oban, "~> 2.11.0"},
      {:phoenix, "~> 1.6.6"},
      {:phoenix_ecto, "~> 4.4.0"},
      {:phoenix_html, "~> 3.2.0"},
      {:phoenix_html_simplified_helpers, "~> 2.1"},
      {:phoenix_live_dashboard, "~> 0.6.5"},
      {:phoenix_live_view, "~> 0.17.7"},
      {:phoenix_live_reload, "~> 1.3.2", only: :dev},
      {:phoenix_pubsub, "~> 2.0"},
      {:phoenix_swoosh, "1.0.1"},
      {:plug, "~> 1.13.3"},
      {:plug_cowboy, "~> 2.5.2"},
      {:poison, "~> 5.0.0"},
      {:postgrex, "~> 0.16.2"},
      {:recaptcha, git: "https://github.com/samueljseay/recaptcha"},
      {:sentry, "~> 8.0.6"},
      {:sobelow, "~> 0.11.1", only: :dev},
      {:slugger, "~> 0.3.0"},
      {:sweet_xml, "~> 0.7.2"},
      {:telemetry_metrics, "~> 0.6.1"},
      {:telemetry_poller, "~> 1.0"},
      {:timex, "~> 3.7.6"},
      {:typed_ecto_schema, "~> 0.3.0"},
      {:tzdata, "~> 1.1.1"},
      {:ueberauth, "~> 0.7.0"},
      {:ueberauth_apple, git: "https://github.com/loopsocial/ueberauth_apple"},
      {:ueberauth_facebook, "~> 0.9.0"},
      {:ueberauth_google, "~> 0.10.1"},
      {:ueberauth_identity, "~> 0.4.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "ci.test": ["ecto.drop", "ecto.create --quiet", "ecto.migrate", "test"],
      "assets.deploy": [
        "esbuild default --minify",
        "sass default --no-source-map --style=compressed",
        "phx.digest"
      ]
    ]
  end
end

defmodule Shuttertop.Guardian.AuthPipeline.Browser do
  @moduledoc false
  @claims %{typ: "access"}
  use Guardian.Plug.Pipeline,
    otp_app: :shuttertop,
    module: Shuttertop.Guardian,
    error_handler: Shuttertop.Guardian.AuthErrorHandlerWeb

  plug(Guardian.Plug.VerifySession, claims: @claims, refresh_from_cookie: true)
  plug(Guardian.Plug.LoadResource, allow_blank: true)
end

defmodule Shuttertop.Guardian.AuthPipeline.JSON do
  @moduledoc false
  @claims %{typ: "access"}
  use Guardian.Plug.Pipeline,
    otp_app: :shuttertop,
    module: Shuttertop.Guardian,
    error_handler: Shuttertop.Guardian.AuthErrorHandler

  plug(Guardian.Plug.VerifyHeader, claims: @claims, scheme: "Bearer")
  plug(Guardian.Plug.LoadResource, allow_blank: true)
end

defmodule Shuttertop.Guardian.AuthPipeline.Authenticate do
  @moduledoc false
  use Guardian.Plug.Pipeline,
    otp_app: :shuttertop,
    module: Shuttertop.Guardian

  plug(Guardian.Plug.EnsureAuthenticated)
end

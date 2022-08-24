defmodule ShuttertopWeb.Api.AuthController do
  require Logger

  use ShuttertopWeb, :controller
  import Ecto.{Query, Changeset}, warn: false

  alias Ecto.Changeset
  alias Shuttertop.{Accounts, Repo}
  alias Shuttertop.Accounts.{Authorization, User}
  alias Shuttertop.Activities
  alias Shuttertop.Guardian.Plug, as: GuardianPlug

  alias Shuttertop.Photos
  alias Shuttertop.Jobs.UserMailerJob
  alias Shuttertop.SocialAuth
  alias Shuttertop.UserFromAuth

  action_fallback(ShuttertopWeb.Api.FallbackController)

  plug(Ueberauth, providers: [:identity], base_path: "/api/auth")

  def callback(%Plug.Conn{assigns: %{ueberauth_failure: fails}} = conn, _) do
    conn
    |> render(ShuttertopWeb.ErrorView, "401.json", message: inspect(fails))
  end

  def callback(%Plug.Conn{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    current_user = GuardianPlug.current_resource(conn)
    authenticate(conn, auth, current_user)
  end

  def callback(conn, %{"state" => "android"} = params) do
    query_params = URI.encode_query(params)

    redirect(conn,
      external:
        "intent://callback?#{query_params}#Intent;package=com.shuttertop.android;scheme=signinwithapple;end"
    )
  end

  def callback(conn, %{"use_bundle_id" => true, "code" => token} = params) do
    current_user = GuardianPlug.current_resource(conn)

    with {:ok, auth} <- SocialAuth.new(conn, :apple, token, params) do
      authenticate(conn, auth, current_user)
    end
  end

  def callback(conn, params) do
    provider_name = :apple

    opts =
      case params["use_bundle_id"] do
        true ->
          config = Application.get_env(:ueberauth, Ueberauth.Strategy.Apple.OAuth)
          client_id = Keyword.get(config, :client_id_native)
          # client_secret = Keyword.get(config, :client_secret_native)
          client_secret = SocialAuth.apple_secret(config, true)

          [
            default_scope: "name email",
            request_path: "/api/auth/apple",
            callback_path: "/api/auth/apple/callback",
            client_id: client_id,
            client_secret: client_secret
          ]

        _ ->
          [
            default_scope: "name email",
            request_path: "/api/auth/apple",
            callback_path: "/api/auth/apple/callback"
          ]
      end

    provider_config = {Ueberauth.Strategy.Apple, opts}

    case Ueberauth.run_callback(conn, provider_name, provider_config) do
      %Plug.Conn{assigns: %{ueberauth_auth: auth}} = conn_success ->
        current_user = GuardianPlug.current_resource(conn_success)
        authenticate(conn_success, auth, current_user)

      %Plug.Conn{assigns: %{ueberauth_failure: fails}} = conn_fail ->
        render(conn_fail, ShuttertopWeb.ErrorView, "401.json", message: inspect(fails))
    end
  end

  def social(conn, %{"token" => token, "provider" => provider} = params) do
    current_user = GuardianPlug.current_resource(conn)
    provider_atom = String.to_existing_atom(provider)

    with {:ok, auth} <- SocialAuth.new(conn, provider_atom, token, params) do
      authenticate(conn, auth, current_user)
    end
  end

  def current_session(conn, _params) do
    with %User{} = current_user <- GuardianPlug.current_resource(conn) do
      jwt = GuardianPlug.current_token(conn)
      claims = GuardianPlug.current_claims(conn)
      exp = Map.get(claims, "exp")
      in_progress = Photos.count_photos_inprogress(current_user.id)

      conn
      |> render("login.json",
        user: Map.put(current_user, :in_progress, in_progress),
        jwt: jwt,
        exp: exp
      )
    end
  end

  def authenticate(conn, auth, current_user) do
    with {:ok, user} <- UserFromAuth.get_or_insert(auth, current_user, Repo) do
      Logger.debug(fn -> "-----------------------user: #{inspect(user)}" end)
      # new_conn = Guardian.Plug.api_sign_in(conn, user)
      new_conn = GuardianPlug.sign_in(conn, user)
      jwt = GuardianPlug.current_token(new_conn)
      claims = GuardianPlug.current_claims(new_conn)
      exp = Map.get(claims, "exp")
      in_progress = Photos.count_photos_inprogress(user.id)
      user_out = Map.put(user, :in_progress, in_progress)

      new_conn
      |> put_resp_header("authorization", "Bearer #{jwt}")
      |> put_resp_header("x-expires", "#{exp}")
      |> render("login.json", user: user_out, jwt: jwt, exp: exp)
    end
  end

  def registration_confirm(conn, %{"token" => token, "email" => email} = _params) do
    a = Accounts.get_authorization_by!(provider: "identity", recovery_token: token, uid: email)

    _u =
      a.user
      |> Ecto.Changeset.cast(%{is_confirmed: true}, [:is_confirmed])
      |> Repo.update!()

    Activities.check_invitations_on_registration(a.user)

    new_conn = GuardianPlug.sign_in(conn, a.user)
    jwt = GuardianPlug.current_token(new_conn)
    claims = GuardianPlug.current_claims(new_conn)
    exp = Map.get(claims, "exp")

    new_conn
    |> put_resp_header("authorization", "Bearer #{jwt}")
    |> put_resp_header("x-expires", "#{exp}")
    |> render("login.json", user: a.user, jwt: jwt, exp: exp)
  end

  def change_password(
        conn,
        %{
          "old_password" => old_password,
          "password" => password
        }
      ) do
    with %User{} = current_user <- GuardianPlug.current_resource(conn) do
      a =
        Accounts.get_authorization_by!(
          provider: "identity",
          uid: current_user.email
        )

      if Bcrypt.verify_pass(old_password, a.token) do
        result = UserFromAuth.reset_password(a, password, password, Repo)
        json(conn, %{success: result == :ok})
      else
        conn
        |> put_status(401)
        |> json(%{success: false})
      end
    end
  end

  def recovery(
        conn,
        %{
          "token" => token,
          "email" => email,
          "password" => password
        }
      ) do
    a = Accounts.get_authorization_by!(provider: "identity", recovery_token: token, uid: email)
    result = UserFromAuth.reset_password(a, password, password, Repo)
    json(conn, %{success: result == :ok})
  end

  def recovery(conn, %{"token" => token, "email" => email} = _params) do
    a = Accounts.get_authorization_by!(provider: "identity", recovery_token: token, uid: email)
    new_conn = GuardianPlug.sign_in(conn, a.user)
    jwt = GuardianPlug.current_token(new_conn)
    claims = GuardianPlug.current_claims(new_conn)
    exp = Map.get(claims, "exp")

    new_conn
    |> put_resp_header("authorization", "Bearer #{jwt}")
    |> put_resp_header("x-expires", "#{exp}")
    |> render("login.json", user: a.user, jwt: jwt, exp: exp)
  end

  def unauthenticated(conn, _params) do
    conn
    |> put_status(:unauthorized)
    |> render(ShuttertopWeb.ErrorView, :"401")
  end

  def password_recovery(conn, %{"email" => email}) do
    auth = Accounts.get_authorization_by(provider: "identity", uid: email)

    case auth do
      %Authorization{} ->
        {:ok, now} = Timex.now() |> Timex.format("%Y%m%d%H%M%S", :strftime)
        token = Bcrypt.hash_pwd_salt("#{now}#{email}")

        auth
        |> Changeset.cast(%{recovery_token: token}, [:recovery_token])
        |> Repo.update!()

        UserMailerJob.enqueue_password_recovery(auth.user)

        json(conn, %{success: true})

      _ ->
        json(conn, %{success: false})
    end
  end

  def logout(conn, %{"token" => token}) do
    current_user = GuardianPlug.current_resource(conn)
    Accounts.delete_device(token, current_user)
    conn = GuardianPlug.sign_out(conn)
    json(conn, %{success: true})
  end

  def logout(conn, _) do
    conn = GuardianPlug.sign_out(conn)
    json(conn, %{success: true})
  end

  # def logout(conn, _, nil, _) do
  #  json conn, %{ success: false }
  # end
end

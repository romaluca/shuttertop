defmodule Shuttertop.SocialAuth do
  @moduledoc """
  Creates `Ueberauth.Auth` structs from OAuth responses.
  """

  alias OAuth2.AccessToken
  alias OAuth2.Client

  require Logger

  @spec new(Plug.Conn.t(), atom, String.t()) :: {:error, String | any} | {:ok, Ueberauth.Auth.t()}
  @spec new(Plug.Conn.t(), atom, String.t(), map) ::
          {:error, String | any} | {:ok, Ueberauth.Auth.t()}
  def new(conn, type, token, params \\ %{})

  def new(_conn, :facebook, token, _params) do
    {_module, config} = Application.get_env(:ueberauth, Ueberauth)[:providers][:facebook]
    token = AccessToken.new(token)
    client = Ueberauth.Strategy.Facebook.OAuth.client(token: token)

    case Client.get(client, "/me?#{user_query(token, config)}") do
      {:ok, %OAuth2.Response{status_code: status_code, body: user}}
      when status_code in 200..399 ->
        {:ok, parse(:facebook, user, token)}

      {:ok, %OAuth2.Response{status_code: 401}} ->
        {:error, "Not authorized."}

      {:error, %OAuth2.Error{reason: reason}} ->
        {:error, reason}

      _other ->
        {:error, "An unknown error occurred."}
    end
  end

  def new(_conn, :google, token, _params) do
    case HTTPoison.get("https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{token}") do
      {:ok, %HTTPoison.Response{status_code: 401, body: _body}} ->
        {:error, "Not authorized."}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      {:ok, %HTTPoison.Response{status_code: status_code, body: user}}
      when status_code in 200..399 ->
        {:ok, parse(:google, user, AccessToken.new(token))}
    end
  end

  def new(_conn, :apple, token, params) do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.Apple.OAuth)
    client_id = Keyword.get(config, :client_id_native)
    # client_secret = Keyword.get(config, :client_secret_native)
    client_secret = apple_secret(config, true)

    header = %{
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept" => "application/json"
    }

    body =
      URI.encode_query(%{
        "client_id" => client_id,
        "client_secret" => client_secret,
        "code" => token,
        "grant_type" => "authorization_code",
        "redirect_uri" => "https://shuttertop.com/api/auth/apple/callback"
      })

    case HTTPoison.post("https://appleid.apple.com/auth/token", body, header) do
      {:ok, %HTTPoison.Response{status_code: 401, body: _body}} ->
        {:error, "Not authorized."}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body_response}}
      when status_code in 200..399 ->
        json_response = Jason.decode!(body_response)
        {:ok, parse(:apple, params, AccessToken.new(json_response["access_token"]))}
    end
  end

  def new(_, _, _token, _secret) do
    {:error, "provider not found"}
  end

  @spec process_response_body(iodata()) :: [any]
  def process_response_body(body) do
    body
    |> Poison.decode!()
    |> Map.take(~w(access_token id_token))
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
  end

  @spec parse(atom, map, OAuth2.AccessToken.t()) :: Ueberauth.Auth.t()
  defp parse(:facebook, user, token) do
    scopes = token.other_params["scope"] || ""
    scopes = String.split(scopes, ",")

    %Ueberauth.Auth{
      provider: :facebook,
      strategy: Ueberauth.Strategy.Facebook,
      uid: user["id"],
      info: %Ueberauth.Auth.Info{
        description: user["bio"],
        email: user["email"],
        first_name: user["first_name"],
        image:
          "http://graph.facebook.com/#{user["id"]}/picture?" <> "type=large&width=600&height=600",
        last_name: user["last_name"],
        name: user["name"],
        urls: %{
          facebook: user["link"],
          website: user["website"]
        }
      },
      extra: %Ueberauth.Auth.Extra{
        raw_info: %{
          token: token,
          user: user
        }
      },
      credentials: %Ueberauth.Auth.Credentials{
        expires: token.expires_at != nil,
        expires_at: token.expires_at,
        scopes: scopes,
        token: token.access_token
      }
    }
  end

  defp parse(:google, user, token) do
    scopes = String.split(token.other_params["scope"] || "", ",")
    user = Jason.decode!(user)

    %Ueberauth.Auth{
      provider: :google,
      strategy: Ueberauth.Strategy.Google,
      uid: user["id"],
      info: %Ueberauth.Auth.Info{
        email: user["email"],
        first_name: user["given_name"],
        image: user["picture"],
        last_name: user["family_name"],
        name: user["name"]
      },
      extra: %Ueberauth.Auth.Extra{
        raw_info: %{
          token: token,
          user: user
        }
      },
      credentials: %Ueberauth.Auth.Credentials{
        expires: token.expires_at != nil,
        expires_at: token.expires_at,
        scopes: scopes,
        refresh_token: token.refresh_token,
        token: token.access_token
      }
    }
  end

  defp parse(:apple, user, token) do
    scopes = String.split("email,name", ",")

    %Ueberauth.Auth{
      provider: :apple,
      strategy: Ueberauth.Strategy.Apple,
      uid: user["uid"],
      info: %Ueberauth.Auth.Info{
        email: user["email"],
        first_name: user["given_name"],
        last_name: user["family_name"],
        name: "#{user["family_name"]} #{user["given_name"]}"
      },
      extra: %Ueberauth.Auth.Extra{
        raw_info: %{
          token: token,
          user: user
        }
      },
      credentials: %Ueberauth.Auth.Credentials{
        expires: token.expires_at != nil,
        expires_at: token.expires_at,
        scopes: scopes,
        refresh_token: token.refresh_token,
        token: token.access_token
      }
    }
  end

  @spec user_query(OAuth2.AccessToken.t(), map) :: binary()
  defp user_query(token, config) do
    %{"appsecret_proof" => appsecret_proof(token)}
    |> Map.merge(%{"fields" => config[:profile_fields]})
    |> URI.encode_query()
  end

  @spec appsecret_proof(OAuth2.AccessToken.t()) :: binary()
  defp appsecret_proof(token) do
    config = Application.get_env(:ueberauth, Ueberauth.Strategy.Facebook.OAuth)
    client_secret = Keyword.get(config, :client_secret)

    token.access_token
    |> hmac(:sha256, client_secret)
    |> Base.encode16(case: :lower)
  end

  @spec hmac(binary, atom, binary) :: binary
  defp hmac(data, type, key) do
    :crypto.mac(:hmac, type, key, data)
  end

  def apple_secret(config, client_id_native \\ false) do
    client_id = if(client_id_native, do: :client_id_native, else: :client_id)
    key_lookup = :"apple_#{client_id}"
    value = :ets.lookup(:app_configs, key_lookup)

    case value do
      [{_, value, date}] ->
        if Date.diff(Date.utc_today(), date) < 7 do
          value
        else
          generate_apple_secret(config, key_lookup, client_id)
        end

      _ ->
        generate_apple_secret(config, key_lookup, client_id)
    end
  end

  defp generate_apple_secret(config, key_lookup, client_id) do
    client_id = Keyword.get(config, client_id)
    private_key = Application.get_env(:shuttertop, :apple_private_key)

    secret =
      UeberauthApple.generate_client_secret(%{
        client_id: client_id,
        key_id: Application.get_env(:shuttertop, :apple_key_id),
        team_id: Application.get_env(:shuttertop, :apple_team_id),
        private_key:
          if(Application.get_env(:shuttertop, :environment) == :prod,
            do: private_key,
            else: Base.decode64!(private_key)
          )
      })

    :ets.insert(:app_configs, {key_lookup, secret, Date.utc_today()})
    secret
  end
end

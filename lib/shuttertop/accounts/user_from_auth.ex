defmodule Shuttertop.UserFromAuth do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false

  alias ExAws.Config
  alias Shuttertop.Accounts
  alias Shuttertop.Accounts.{Authorization, User}
  alias Shuttertop.Activities
  alias Shuttertop.Repo
  alias Ueberauth.Auth

  require Logger

  @spec get_or_insert(Ueberauth.Auth.t(), User.t() | nil, Ecto.Repo.t()) :: {:error, any} | any
  def get_or_insert(auth, current_user, repo) do
    case auth_and_validate(auth, repo) do
      {:error, :not_found} ->
        register_user_from_auth(auth, current_user, repo)

      {:error, reason} ->
        {:error, reason}

      authorization ->
        if authorization.expires_at && authorization.expires_at < Guardian.timestamp() do
          replace_authorization(authorization, auth, current_user, repo)
        else
          user_from_authorization(auth, authorization, current_user, repo)
        end
    end
  end

  @spec reset_password(Authorization.t(), String.t(), String.t(), Ecto.Repo.t()) ::
          :ok
          | {:error,
             :invalid_email
             | :password_confirmation_does_not_match
             | :password_empty
             | :password_is_null
             | :password_length_is_less_than_8}
  def reset_password(auth, password, password_confirmation, _repo) do
    case password do
      nil ->
        {:error, :password_is_null}

      "" ->
        {:error, :password_empty}

      ^password_confirmation ->
        case validate_pw_length(password, auth.uid) do
          :ok ->
            auth
            |> cast(%{token: Bcrypt.hash_pwd_salt(password), recovery_token: nil}, [
              :token,
              :recovery_token
            ])
            |> Repo.update!()

            auth.user
            |> cast(%{is_confirmed: true}, [:is_confirmed])
            |> Repo.update!()

            :ok

          a ->
            a
        end

      _ ->
        {:error, :password_confirmation_does_not_match}
    end
  end

  @spec validate_auth_for_registration(Ueberauth.Auth.t() | any) ::
          {:error,
           :password_is_null
           | :password_empty
           | :password_confirmation_does_not_match
           | :password_length_is_less_than_8
           | :invalid_email}
          | :ok
  defp validate_auth_for_registration(%Auth{provider: :identity} = auth) do
    pw = Map.get(auth.credentials.other, :password)
    pwc = Map.get(auth.credentials.other, :password_confirmation)
    email = auth.info.email

    case pw do
      nil ->
        {:error, :password_is_null}

      "" ->
        {:error, :password_empty}

      ^pwc ->
        validate_pw_length(pw, email)

      _ ->
        {:error, :password_confirmation_does_not_match}
    end
  end

  defp validate_auth_for_registration(_), do: :ok

  @spec validate_pw_length(binary, binary) ::
          {:error,
           :password_length_is_less_than_8
           | :invalid_email}
          | :ok
  defp validate_pw_length(pw, email) when is_binary(pw) do
    if String.length(pw) >= 8 do
      validate_email(email)
    else
      {:error, :password_length_is_less_than_8}
    end
  end

  @spec validate_email(binary) :: {:error, :invalid_email} | :ok
  defp validate_email(email) when is_binary(email) do
    case Regex.run(~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/, email) do
      nil ->
        {:error, :invalid_email}

      [_] ->
        :ok
    end
  end

  @spec register_user_from_auth(Ueberauth.Auth.t(), User.t() | nil, Ecto.Repo.t()) ::
          {:error, any} | User.t()
  defp register_user_from_auth(auth, current_user, repo) do
    case validate_auth_for_registration(auth) do
      :ok ->
        case repo.transaction(fn ->
               create_user_from_auth(auth, current_user, repo)
             end) do
          {:ok, response} -> response
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec replace_authorization(Authorization.t(), Ueberauth.Auth.t(), User.t(), Ecto.Repo.t()) ::
          {:ok, User.t()} | {:error, any}
  defp replace_authorization(authorization, auth, current_user, repo) do
    case validate_auth_for_registration(auth) do
      :ok ->
        case user_from_authorization(auth, authorization, current_user, repo) do
          {:ok, user} ->
            case repo.transaction(fn ->
                   repo.delete(authorization)
                   authorization_from_auth(user, auth, repo)
                   user
                 end) do
              {:ok, user} -> {:ok, user}
              {:error, reason} -> {:error, reason}
            end

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec user_from_authorization(Ueberauth.Auth.t(), Authorization.t(), User.t(), Ecto.Repo.t()) ::
          {:error,
           :user_not_found
           | :user_does_not_match
           | :user_not_confirmed}
          | {:ok, User.t()}
  defp user_from_authorization(auth, authorization, current_user, repo) do
    case repo.one(Ecto.assoc(authorization, :user)) do
      nil ->
        {:error, :user_not_found}

      user ->
        cond do
          current_user && current_user.id != user.id ->
            {:error, :user_does_not_match}

          !user.is_confirmed ->
            {:error, :user_not_confirmed}

          true ->
            if is_nil(user.upload), do: upload_avatar(user, auth)

            authorization
            |> Ecto.Changeset.change(updated_at: NaiveDateTime.local_now())
            |> repo.update()

            {:ok, user}
        end
    end
  end

  @spec create_user_from_auth(Ueberauth.t(), User.t() | nil, Ecto.Repo.t()) ::
          {:ok, User.t() | nil}
  defp create_user_from_auth(auth, current_user, repo) do
    user =
      current_user ||
        cond do
          auth.info.email != nil ->
            create_user_from_auth_by_email(auth, repo)

          auth.provider == :facebook or auth.provider == :apple ->
            create_user_from_auth_with_uid(auth, repo)

          true ->
            nil
        end

    authorization_from_auth(user, auth, repo)

    {:ok, user}
  end

  @spec create_user_from_auth_with_uid(Ueberauth.Auth.t(), Ecto.Repo.t()) :: User.t()
  defp create_user_from_auth_with_uid(auth, repo) do
    case Accounts.get_authorization_by(uid: auth.uid, provider: Atom.to_string(auth.provider)) do
      %Authorization{} = au ->
        Accounts.get_user_by(id: au.user_id)

      _ ->
        dt = DateTime.to_unix(DateTime.utc_now())
        info = Map.put(auth.info, :email, "#{dt}@fake.shuttertop.com")

        auth
        |> Map.put(:info, info)
        |> create_user(repo)
    end
  end

  @spec create_user_from_auth_by_email(Ueberauth.Auth.t(), Ecto.Repo.t()) :: User.t()
  defp create_user_from_auth_by_email(auth, repo) do
    case Repo.get_by(User, email: auth.info.email) do
      %User{is_confirmed: false} = user ->
        _e =
          user
          |> Ecto.Changeset.change(is_confirmed: true)
          |> Repo.update()

        Accounts.get_user_by(email: auth.info.email)

      %User{is_confirmed: true} ->
        Accounts.get_user_by(email: auth.info.email)

      nil ->
        create_user(auth, repo)
    end
  end

  @spec create_user(Ueberauth.Auth.t(), Ecto.Repo.t()) :: User.t() | any
  defp create_user(auth, repo) do
    Logger.info("user: #{inspect(auth.info)}")

    is_social_auth =
      auth.provider == :facebook || auth.provider == :google || auth.provider == :apple

    name =
      auth
      |> name_from_auth()
      |> unique_user_name()

    u = User.registration_changeset(%User{}, scrub(%{email: auth.info.email, name: name}))

    result =
      u
      |> cast(%{is_confirmed: is_social_auth}, [:is_confirmed])
      |> repo.insert

    case result do
      {:ok, user} ->
        if is_social_auth do
          upload_avatar(user, auth)
          Activities.check_invitations_on_registration(user)
        end

        user

      {:error, reason} ->
        repo.rollback(reason)
    end
  end

  @spec upload_avatar(User.t(), Ueberauth.Auth.t()) :: User.t()
  defp upload_avatar(user, auth) do
    Logger.debug("upload_avatar start")

    {:ok, now} =
      Timex.now()
      |> Timex.format("%Y%m%d%H%M%S", :strftime)

    filename = "#{now}_U_#{user.id}.jpg"
    local_path = "/tmp/#{filename}"

    try do
      url =
        case auth.provider do
          :facebook ->
            auth.info.image <> "&width=400"

          :google ->
            String.replace(auth.info.image || "", "=s96-c", "=s384-c")

          _ ->
            nil
        end

      Logger.debug("upload url: #{inspect(url)}")

      if !is_nil(url) do
        %HTTPoison.Response{body: body, status_code: status_code} =
          HTTPoison.get!(url, [], follow_redirect: true)

        if status_code == 200 do
          File.write!(local_path, body)
          paths = %{local_path => {"users", filename}}

          paths
          |> Task.async_stream(
            fn {src_path, {_dest_path, filename}} ->
              Logger.info("------uploading_file: #{src_path} in #{filename}")
              config = Config.new(:s3, %{region: "eu-west-1"})

              ExAws.S3.put_object("img.shuttertop.com", filename, File.read!(src_path))
              |> ExAws.request!(config)

              File.rm(src_path)
            end,
            max_concurrency: 10
          )
          |> Stream.run()

          Accounts.update_upload(user, filename)
        else
          Logger.error("Error in upload_avatar status code: #{status_code} url: #{url}")
        end
      end
    rescue
      x -> Logger.error("Error in upload_avatar: #{inspect(x)}")
    end

    user
  end

  @spec unique_user_name(binary) :: binary()
  defp unique_user_name(name) do
    exists = Accounts.get_user_by(name: name)

    if exists do
      unique_user_name("#{name} #{:rand.uniform(99999)}")
    else
      name
    end
  end

  @spec auth_and_validate(Ueberauth.Auth.t(), Ecto.Repo.t()) ::
          {:error,
           :not_found
           | :password_does_not_match
           | :password_required}
          | Authorization.t()
  defp auth_and_validate(%{provider: :identity} = auth, _) do
    ret =
      if is_nil(uid_from_auth(auth)) do
        nil
      else
        Accounts.get_authorization_by(
          uid: uid_from_auth(auth),
          provider: to_string(auth.provider)
        )
      end

    case ret do
      nil ->
        {:error, :not_found}

      authorization ->
        case auth.credentials.other.password do
          pass when is_binary(pass) ->
            if Bcrypt.verify_pass(auth.credentials.other.password, authorization.token) do
              authorization
            else
              {:error, :password_does_not_match}
            end

          _ ->
            {:error, :password_required}
        end
    end
  end

  defp auth_and_validate(%{provider: service} = auth, _)
       when service in [:google, :facebook, :apple] do
    uid = uid_from_auth(auth)
    provider = to_string(auth.provider)

    case Accounts.get_authorization_by(
           uid: uid,
           provider: provider
         ) do
      nil ->
        {:error, :not_found}

      authorization ->
        if authorization.uid == uid do
          authorization
        else
          {:error, :uid_mismatch}
        end
    end
  end

  defp auth_and_validate(auth, repo) do
    case repo.get_by(
           Authorization,
           uid: uid_from_auth(auth),
           provider: to_string(auth.provider)
         ) do
      nil ->
        {:error, :not_found}

      authorization ->
        if authorization.token == auth.credentials.token do
          authorization
        else
          {:error, :token_mismatch}
        end
    end
  end

  @spec authorization_from_auth(User.t(), Ueberauth.Auth.t(), Ecto.Repo.t()) ::
          Authorization.t() | any
  defp authorization_from_auth(user, auth, repo) do
    authorization = Ecto.build_assoc(user, :authorizations)

    result =
      repo.insert(
        Authorization.changeset(
          authorization,
          scrub(%{
            provider: to_string(auth.provider),
            uid: uid_from_auth(auth),
            token: token_from_auth(auth),
            refresh_token: auth.credentials.refresh_token,
            expires_at: auth.credentials.expires_at,
            password: password_from_auth(auth),
            password_confirmation: password_confirmation_from_auth(auth)
          })
        )
      )

    case result do
      {:ok, the_auth} -> the_auth
      {:error, reason} -> repo.rollback(reason)
    end
  end

  @spec name_from_auth(Ueberauth.t()) :: binary()
  defp name_from_auth(auth) do
    if auth.info.name do
      auth.info.name
    else
      [auth.info.first_name, auth.info.last_name]
      |> Enum.filter(&(&1 != nil and String.trim(&1) != ""))
      |> Enum.join(" ")
    end
  end

  @spec token_from_auth(Ueberauth.Auth.t()) :: binary() | nil
  defp token_from_auth(%{provider: :identity} = auth) do
    case auth do
      %{credentials: %{other: %{password: pass}}} when not is_nil(pass) ->
        Bcrypt.hash_pwd_salt(pass)

      _ ->
        nil
    end
  end

  defp token_from_auth(auth), do: auth.credentials.token

  @spec uid_from_auth(Ueberauth.Auth.t()) :: Integer.t()
  defp uid_from_auth(auth), do: auth.uid

  @spec password_from_auth(Ueberauth.Auth.t() | any) :: binary() | nil
  defp password_from_auth(%{provider: :identity} = auth) do
    auth.credentials.other.password
  end

  defp password_from_auth(_), do: nil

  @spec password_confirmation_from_auth(Ueberauth.Auth.t() | any) :: binary() | nil
  defp password_confirmation_from_auth(%{provider: :identity} = auth) do
    auth.credentials.other.password_confirmation
  end

  defp password_confirmation_from_auth(_), do: nil

  @spec scrub(map) :: map
  defp scrub(params) do
    result =
      Enum.into(
        Enum.filter(params, fn
          {_, val} when is_binary(val) -> String.trim(val) != ""
          {_, val} when is_nil(val) -> false
          _ -> true
        end),
        %{}
      )

    result
  end
end

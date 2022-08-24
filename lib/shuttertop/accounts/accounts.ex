defmodule Shuttertop.Accounts do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  require Shuttertop.Constants

  alias Shuttertop.{Paginator, Repo}
  alias Shuttertop.Accounts.{Authorization, BlockedUser, Device, Invitation, User}
  alias Shuttertop.Activities.Activity
  alias Shuttertop.{Activities, Follows}
  alias Shuttertop.Constants, as: Const

  require Logger

  @spec create_device(map(), User.t()) :: {:ok, Device.t()} | {:error, Ecto.Changeset.t()}
  def create_device(attrs \\ %{}, user) do
    ret =
      user
      |> Ecto.build_assoc(:devices)
      |> Device.changeset(attrs)
      |> Repo.insert(
        on_conflict: [set: [updated_at: Timex.now()]],
        conflict_target: [:token, :platform]
      )

    case ret do
      {:ok, device} ->
        subscribe_topics(device.token, user.language, device.platform)
        ret

      _ ->
        ret
    end
  end

  @spec get_device_by!(binary(), User.t()) :: Device.t()
  def get_device_by!(token, current_user) do
    Repo.one!(from(d in Device, where: d.user_id == ^current_user.id and d.token == ^token))
  end

  @spec delete_device_by_token(binary()) :: {integer(), nil | [term()]}
  def delete_device_by_token(token) do
    Repo.delete_all(from(d in Device, where: d.token == ^token))
  end

  @spec delete_device(binary(), User.t()) :: {integer(), nil | [term()]}
  def delete_device(token, %User{} = current_user) do
    device =
      Repo.one(from(d in Device, where: d.user_id == ^current_user.id and d.token == ^token))

    if !is_nil(device) do
      env = if(Application.get_env(:shuttertop, :environment) == :prod, do: "", else: "-test")
      topic = "-#{current_user.language}-#{device.platform}#{env}"
      _ret = Fcmex.Subscription.unsubscribe("#{Const.fcm_topic_top_week()}#{topic}", token)
      _ret = Fcmex.Subscription.unsubscribe("#{Const.fcm_topic_new_contest()}#{topic}", token)
      Repo.delete(device)
    end
  end

  def clean_devices() do
    t = Timex.now() |> Timex.shift(days: -90)

    from(d in Device, where: d.updated_at < ^t)
    |> Repo.delete_all()
  end

  @spec get_admin_ids() :: [Integer.t()]
  def get_admin_ids() do
    from(u in User,
      where: u.type == ^Const.user_type_admin(),
      select: u.id
    )
    |> Repo.all()
  end

  def count_users(), do: Repo.one(from(u in User, select: count(u.id)))

  @spec get_users(map, User.t() | nil) :: any
  def get_users(%{} = params, current_user \\ nil) do
    cond do
      !is_nil(params[:limit]) ->
        current_user
        |> users_query(params)
        |> limit(^params.limit)
        |> Repo.all()

      !is_nil(params[:one]) ->
        current_user
        |> users_query(params)
        |> limit(1)
        |> Repo.one()

      true ->
        current_user
        |> users_query(params)
        |> Paginator.paginate(params)
    end
  end

  @spec users_query(User.t() | nil, map) :: Ecto.Query.t()
  defp users_query(current_user, params) do
    current_user
    |> users_current_user()
    |> where([c], c.type != ^Const.user_type_tester())
    |> users_filter_by_params(params |> Enum.to_list(), current_user)
  end

  @spec users_filter_by_params(Ecto.Query.t(), list(), User.t() | nil) :: Ecto.Query.t()
  defp users_filter_by_params(query, params, current_user) do
    Enum.reduce(params, query, fn
      {:country_id, country_id}, query ->
        filter_country(query, country_id)

      {:search, search}, query ->
        filter_search(query, search)

      {:order, order}, query ->
        users_order(query, order)

      {:blocked, blocked}, query ->
        filter_blocked(query, blocked, current_user)

      {:days, days}, query ->
        filter_days(query, days, current_user)

      {:emails, emails}, query ->
        filter_emails(query, emails)

      _, query ->
        query
    end)
  end

  @spec users_current_user(User.t() | nil) :: Ecto.Query.t()
  defp users_current_user(current_user) do
    case current_user do
      %User{} ->
        from(
          c in User,
          left_join: a in Activity,
          on: [user_to_id: c.id, user_id: ^current_user.id, type: ^Const.action_follow_user()],
          left_join: b in BlockedUser,
          on: [user_id: ^current_user.id, user_to_id: c.id],
          preload: [activities_to: a, blocked_users: b],
          where: c.is_confirmed
        )

      _ ->
        from(c in User,
          left_join: a in Activity,
          on: [id: 0],
          where: c.is_confirmed,
          preload: [activities_to: a]
        )
    end
  end

  @spec filter_blocked(Ecto.Query.t(), String.t(), User.t() | nil) :: Ecto.Query.t()
  defp filter_blocked(query, _blocked, current_user) do
    case current_user do
      %User{} ->
        where(query, [u, activity, blocked_users], not is_nil(blocked_users.user_to_id))

      _ ->
        query
    end
  end

  @spec filter_days(Ecto.Query.t(), String.t(), User.t() | nil) :: Ecto.Query.t()
  defp filter_days(query, days, current_user) do
    time_start =
      Timex.today()
      |> Timex.shift(days: -1 * String.to_integer(days))
      |> Timex.to_datetime()

    sub_query =
      from(
        a in Activity,
        group_by: :user_to_id,
        select: %{user_to_id: a.user_to_id, score_partial: sum(a.points)},
        where: a.points > 0 and a.inserted_at >= ^time_start
      )

    case current_user do
      %User{} ->
        query
        |> join(:left, [u], a in subquery(sub_query), on: u.id == a.user_to_id)
        |> select([u, activity, blocked_users, a], %User{u | score_partial: a.score_partial})
        |> order_by(
          [u, activity, blocked_users, a],
          fragment("? DESC NULLS LAST", a.score_partial)
        )

      _ ->
        query
        |> join(:left, [u], a in subquery(sub_query), on: u.id == a.user_to_id)
        |> select([u, a], %User{u | score_partial: a.score_partial})
        |> order_by([u, a], fragment("? DESC NULLS LAST", a.score_partial))
    end
  end

  @spec filter_emails(Ecto.Query.t(), list(String.t())) :: Ecto.Query.t()
  defp filter_emails(query, emails) do
    query
    |> where([u], u.email in ^emails)
    |> order_by([p], desc: p.name)
  end

  @spec filter_country(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  defp filter_country(query, country_id) do
    where(query, [u], u.country_code == ^country_id)
  end

  @spec filter_search(Ecto.Query.t(), String.t()) :: Ecto.Query.t()
  defp filter_search(query, search) do
    where(query, [u], ilike(u.name, ^"%#{search}%"))
  end

  @spec users_order(Ecto.Query.t(), atom | any) :: Ecto.Query.t()
  defp users_order(query, order) do
    case order do
      :trophies ->
        order_by(query, [p], desc: p.winner_count, desc: p.score)

      :name ->
        order_by(query, [p], p.name)

      _ ->
        order_by(query, [p], desc: p.score)
    end
  end

  @spec get_user(integer()) :: User.t() | nil
  def get_user(id), do: Repo.get(User, id)

  @spec get_user!(integer()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  @spec get_user_by!(Keyword.t() | map(), User.t() | nil) :: User.t()
  def get_user_by!(list, current_user \\ nil)

  def get_user_by!(list, current_user) do
    current_user
    |> users_current_user()
    |> Repo.get_by!(list)
  end

  @spec get_user_by(Keyword.t() | map(), User.t() | nil) :: User.t() | nil
  def get_user_by(list, current_user \\ nil)

  def get_user_by(list, current_user) do
    current_user
    |> users_current_user()
    |> Repo.get_by(list)
  end

  @spec get_query_authorization() :: Ecto.Query.t()
  defp get_query_authorization do
    from(a in Authorization, preload: [:user])
  end

  @spec get_authorizations(map()) :: any
  def get_authorizations(%{} = params) do
    from(a in Authorization, preload: [user: :devices])
    |> order_by([a], desc: a.updated_at)
    |> Paginator.paginate(params)
  end

  @spec get_authorization_by(Keyword.t() | map()) :: Authorization.t() | nil
  def get_authorization_by(list) do
    get_query_authorization()
    |> Repo.get_by(list)
  end

  @spec get_authorization_by!(Keyword.t() | map()) :: Authorization.t()
  def get_authorization_by!(list) do
    get_query_authorization()
    |> Repo.get_by!(list)
  end

  @spec get_users_nofication_mail_by_lang(binary(), integer(), integer(), integer()) :: [User.t()]
  def get_users_nofication_mail_by_lang(lang, limit, offset, except_id) do
    id = except_id || -1

    Repo.all(
      from(
        u in User,
        where:
          u.id != ^id and u.language == ^lang and u.notifies_enabled and
            not like(u.email, "fake_%@shuttertop.com"),
        limit: ^limit,
        offset: ^offset
      )
    )
  end

  @spec get_country_codes :: [{binary(), binary()}]
  def get_country_codes do
    ele =
      Repo.all(
        from(
          u in User,
          distinct: u.country_code,
          select: u.country_code,
          where: not is_nil(u.country_code)
        )
      )

    Enum.map(ele, fn c ->
      e =
        :alpha2
        |> Countries.filter_by(to_charlist(c))
        |> Enum.at(0)

      case e do
        nil ->
          nil

        _ ->
          {e.name, e.alpha2}
      end
    end)
  end

  @spec update_upload(User.t(), binary() | nil) :: any
  def update_upload(user, filename) do
    inc = if user.upload, do: 0, else: 5

    user
    |> cast(%{upload: filename, score: user.score + inc}, [:upload, :score])
    |> Repo.update!()

    if filename do
      Activities.trace_first_avatar(user)
    end
  end

  @spec reset_notify_count(User.t()) :: User.t()
  def reset_notify_count(user) do
    user
    |> cast(%{notify_count: 0}, [:notify_count])
    |> Repo.update!()
  end

  @spec reset_notify_message_count(User.t()) :: User.t()
  def reset_notify_message_count(user) do
    user
    |> cast(%{notify_message_count: 0}, [:notify_message_count])
    |> Repo.update!()
  end

  defp subscribe_topics(token, language, platform) do
    Task.start(fn ->
      env = if(Application.get_env(:shuttertop, :environment) == :prod, do: "", else: "-test")
      topic = "-#{language}-#{platform}#{env}"
      Fcmex.Subscription.subscribe("#{Const.fcm_topic_top_week()}#{topic}", token)
      Fcmex.Subscription.subscribe("#{Const.fcm_topic_new_contest()}#{topic}", token)
    end)
  end

  @spec create_user(map(), boolean()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(attrs, robot_error \\ false) do
    if robot_error do
      %User{}
      |> User.form_registration_changeset(attrs)
      |> add_error(:base, "Conferma di non essere un robot!")
      |> Repo.insert()
    else
      %User{}
      |> User.form_registration_changeset(attrs)
      |> Repo.insert()
    end
  end

  @spec update_user(User.t(), map(), User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(%User{} = user, params, %User{} = current_user) do
    if current_user.type == Const.user_type_admin() do
      user
      |> User.changeset_admin(params)
      |> Repo.update()
    else
      user
      |> User.changeset(params)
      |> Repo.update()
    end
  end

  @spec create_invitation(binary, User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_invitation(email, user) do
    hashed = get_hashed_email(email)

    attrs = %{
      email_hash: hashed
    }

    user
    |> Ecto.build_assoc(:invitations)
    |> Invitation.changeset(attrs)
    |> Repo.insert()
  end

  @spec create_blocked_user(User.t(), User.t()) ::
          {:ok, BlockedUser.t()} | {:error, Ecto.Changeset.t()}
  def create_blocked_user(user_to, current_user) do
    attrs = %{
      user_id: current_user.id,
      user_to_id: user_to.id
    }

    ret =
      %BlockedUser{}
      |> BlockedUser.changeset(attrs)
      |> Repo.insert()

    _ret =
      case ret do
        {:ok, _} ->
          Follows.remove(user_to, current_user)

        _ ->
          nil
      end

    ret
  end

  @spec delete_blocked_user(User.t(), User.t()) :: {:ok | :error}
  def delete_blocked_user(user_to, current_user) do
    ret =
      Repo.delete_all(
        from(u in BlockedUser,
          where:
            u.user_to_id == ^user_to.id and
              u.user_id == ^current_user.id
        )
      )

    case ret do
      {0, _} ->
        {:error}

      _ ->
        {:ok}
    end
  end

  @spec get_hashed_email(binary) :: binary
  def get_hashed_email(email) do
    :crypto.hash(:sha256, email)
    |> Base.encode16()
    |> String.downcase()
  end
end

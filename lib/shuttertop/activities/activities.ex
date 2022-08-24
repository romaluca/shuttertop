defmodule Shuttertop.Activities do
  @moduledoc false
  import Ecto.{Query, Changeset}, warn: false
  require Logger
  require Shuttertop.Constants

  alias Shuttertop.{Paginator, Repo}
  alias Ecto.Multi
  alias Shuttertop.Activities.Activity
  alias Shuttertop.{Accounts}
  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Accounts.{Invitation, User}
  alias Shuttertop.Jobs.NotifyJob

  @spec get_activity_by(Keyword.t() | map) :: Activity.t() | nil
  def get_activity_by(list)

  def get_activity_by(list) do
    Repo.get_by(Activity, list)
  end

  @spec get_latest_scores(User.t()) :: Page.t()
  @spec get_latest_scores(User.t(), map) :: Page.t()
  def get_latest_scores(%User{} = current_user, params \\ %{}) do
    user =
      if is_nil(params["user_id"]) || params["user_id"] == current_user.id do
        current_user
      else
        Repo.get!(from(u in User, select: [:id]), params["user_id"])
      end

    # Repo.paginate(
    Paginator.paginate(
      from(a in Activity,
        left_join: c in assoc(a, :contest),
        left_join: photo in assoc(a, :photo),
        preload: [:user, :user_to, photo: photo, contest: c],
        where: a.user_to_id == ^user.id and a.points > 0,
        order_by: [desc: :id]
      ),
      params
    )
  end

  @spec get_latest_notifies(User.t()) :: Page.t()
  @spec get_latest_notifies(User.t(), map) :: Page.t()
  def get_latest_notifies(%User{} = user, params \\ %{}) do
    from(a in Activity,
      left_join: c in assoc(a, :contest),
      left_join: photo in assoc(a, :photo),
      preload: [:user, :user_to, photo: photo, contest: c],
      where:
        (a.user_id != ^user.id or a.type == ^Const.action_win()) and a.user_to_id == ^user.id,
      order_by: [desc: :id]
    )
    |> Paginator.paginate_with_more(params)
  end

  @spec get_latest_activities(map, User.t()) :: Page.t()
  def get_latest_activities(params, user) do
    case params do
      %{:contest_id => _contest_id} ->
        get_latest_contest_activities(params, user)

      %{:user_id => _user_id} ->
        get_latest_user_activities(params, user)

      _ ->
        get_latest_booked_activities(params, user)
    end
  end

  @spec get_activities_by_ids([Integer.t()], User.t()) :: [Activity.t()]
  def get_activities_by_ids(ids, user) do
    from(a in Activity,
      left_join: c in assoc(a, :contest),
      left_join: c_activities in assoc(c, :activities),
      on:
        c_activities.user_id == ^user.id and
          c_activities.type == ^Const.action_follow_contest(),
      left_join: u in assoc(a, :user),
      left_join: u_activities in assoc(u, :activities_to),
      on: u_activities.user_id == ^user.id and u_activities.type == ^Const.action_follow_user(),
      left_join: photo in assoc(a, :photo),
      left_join: p_activities in assoc(photo, :activities),
      on: p_activities.user_id == ^user.id and p_activities.type == ^Const.action_vote(),
      left_join: user_photo in assoc(c, :user_photo),
      on: user_photo.user_id == ^user.id,
      preload: [
        :user_to,
        user: u,
        photo: {photo, activities: p_activities},
        contest: {c, user_photo: user_photo, activities: c_activities, winner: :user}
      ],
      where: a.id in ^ids,
      order_by: [desc: :id]
    )
    |> Repo.all()
  end

  @spec get_latest_contest_activities(%{contest_id: Integer.t()}, User.t()) :: Page.t()
  def get_latest_contest_activities(%{contest_id: contest_id} = params, user) do
    query =
      case user do
        nil ->
          from(a in Activity,
            left_join: u in assoc(a, :user),
            left_join: photo in assoc(a, :photo),
            preload: [:user_to, user: u, photo: photo],
            where: a.contest_id == ^contest_id,
            order_by: [desc: :id]
          )

        _ ->
          from(a in Activity,
            left_join: u in assoc(a, :user),
            left_join: u_activities in assoc(u, :activities),
            on:
              u_activities.user_id == ^user.id and
                u_activities.type == ^Const.action_follow_user(),
            left_join: photo in assoc(a, :photo),
            left_join: p_activities in assoc(photo, :activities),
            on: p_activities.user_id == ^user.id and p_activities.type == ^Const.action_vote(),
            preload: [:user_to, user: u, photo: {photo, activities: p_activities}],
            where: a.contest_id == ^contest_id and u.id != ^user.id,
            order_by: [desc: :id]
          )
      end

    # Repo.paginate(query, params)
    Paginator.paginate(query, params)
  end

  @spec get_latest_user_activities(%{user_id: Integer.t()}, User.t()) :: Page.t()
  def get_latest_user_activities(%{user_id: user_id} = params, user) do
    query =
      case user do
        nil ->
          from(a in Activity,
            left_join: c in assoc(a, :contest),
            left_join: photo in assoc(a, :photo),
            preload: [:user_to, photo: photo, contest: c],
            where: a.user_id == ^user_id
          )

        _ ->
          from(a in Activity,
            left_join: c in assoc(a, :contest),
            left_join: photo in assoc(a, :photo),
            left_join: c_activities in assoc(c, :activities),
            on:
              c_activities.user_id == ^user.id and
                c_activities.type == ^Const.action_follow_contest(),
            left_join: p_activities in assoc(photo, :activities),
            on: p_activities.user_id == ^user.id and p_activities.type == ^Const.action_vote(),
            preload: [
              :user_to,
              photo: {photo, activities: p_activities},
              contest: {c, activities: c_activities}
            ],
            where: a.user_id == ^user_id
          )
      end

    query =
      if is_nil(params[:in_progress]) do
        query
        |> order_by([a], desc: a.id)
      else
        where(
          query,
          [a, c],
          not is_nil(c) and not c.is_expired and
            (a.type == ^Const.action_joined() or a.type == ^Const.action_contest_created())
        )
        |> order_by([a, c], asc: c.expiry_at)
      end

    # Repo.paginate(query, params)
    Paginator.paginate(query, params)
  end

  @spec page(Ecto.Query.t(), map) :: Ecto.Query.t()
  def page(query, %{"page" => page}) do
    {o, _} = Integer.parse(page)
    o1 = o * 30

    query
    |> limit(80)
    |> offset(^o1)
  end

  @spec get_latest_booked_activities(map, User.t()) :: Page.t()
  def get_latest_booked_activities(params, %User{} = user) do
    contest_ids =
      Repo.all(
        from(ac in Activity,
          where: ac.user_id == ^user.id and ac.type == ^Const.action_follow_contest(),
          select: ac.contest_id
        )
      )

    user_ids =
      Repo.all(
        from(ac in Activity,
          where: ac.user_id == ^user.id and ac.type == ^Const.action_follow_user(),
          select: ac.user_to_id
        )
      )

    q =
      from(a in Activity,
        as: :activity,
        select: a.id,
        left_join: photo in assoc(a, :photo),
        where:
          ((a.type == ^Const.action_contest_created() or a.type == ^Const.action_win()) and
             a.user_id != ^user.id) or
            (a.type == ^Const.action_joined() and photo.user_id != ^user.id),
        order_by: [desc: :id]
      )

    q =
      case params do
        %{not_booked: _a} ->
          where(q, [a], a.user_id not in ^user_ids and a.contest_id not in ^contest_ids)

        _ ->
          where(q, [a], a.user_id in ^user_ids or a.contest_id in ^contest_ids)
      end

    p = Paginator.paginate_with_more(q, params)
    activities = get_activities_by_ids(p.entries, user)
    %Shuttertop.Page{p | entries: activities}
  end

  @spec get_latest_all_activities(map, User.t()) :: Page.t()
  def get_latest_all_activities(%{} = params, %User{} = _user) do
    Paginator.paginate(
      from(a in Activity,
        preload: [
          :user_to,
          :user,
          :photo,
          :contest
        ],
        order_by: [desc: :id]
      ),
      params
    )
  end

  @spec trace_first_avatar(User.t()) :: any
  def trace_first_avatar(%User{id: id} = user) do
    activity =
      Repo.one(
        from(a in Activity,
          select: [:id],
          where: a.user_id == ^id and a.type == ^Const.action_first_avatar()
        )
      )

    unless activity do
      Multi.new()
      |> multi_activity(:create, :basic, %Activity{
        user_id: id,
        type: Const.action_first_avatar(),
        points: Const.points_first_avatar(),
        user_to_id: id
      })
      |> multi_update_user_score(user)
      |> Repo.transaction()
    end
  end

  @spec multi_update_user_score(Ecto.Multi.t(), User.t()) :: Ecto.Multi.t()
  defp multi_update_user_score(multi, %User{id: id} = _user) do
    Multi.update_all(
      multi,
      :score,
      from(u in User,
        where: u.id == ^id
      ),
      inc: [score: 10]
    )
  end

  @spec multi_activity(Multi.t(), :delete, Activity.t()) :: Multi.t()
  def multi_activity(multi, :delete, %Activity{} = activity) do
    query =
      from(a in Activity,
        where:
          a.user_id == ^activity.user_id and a.type == ^activity.type and
            a.user_to_id == ^activity.user_to_id
      )

    query =
      if is_nil(activity.contest_id) do
        query
      else
        where(query, [a], a.contest_id == ^activity.contest_id)
      end

    query =
      if is_nil(activity.photo_id) do
        query
      else
        where(query, [a], a.photo_id == ^activity.photo_id)
      end

    Multi.delete_all(multi, :activity, query)
  end

  @spec multi_activity(Multi.t(), :create, any, Activity.t()) :: Multi.t()
  def multi_activity(multi, :create, op, %Activity{} = activity) do
    vchangeset = Activity.changeset(op, activity)
    Multi.insert(multi, :activity, vchangeset)
  end

  @spec check_invitations_on_registration(User.t()) :: Task.t()
  def check_invitations_on_registration(user) do
    Task.async(fn ->
      hashed = Accounts.get_hashed_email(user.email)

      users =
        Repo.all(
          from(u in User, inner_join: i in Invitation, on: [user_id: u.id, email_hash: ^hashed])
        )

      for u <- users do
        Multi.new()
        |> multi_activity(:create, :basic, %Activity{
          user_id: user.id,
          user_to_id: u.id,
          type: Const.action_friend_signed()
        })
        |> multi_update_user_notify_count(u, 1)
        |> Repo.transaction()
        |> send_notify()
      end

      Repo.delete_all(from(i in Invitation, where: i.email_hash == ^hashed))
    end)
  end

  @spec multi_update_user_notify_count(Multi.t(), User.t(), Integer.t()) :: Multi.t()
  defp multi_update_user_notify_count(multi, user, inc) do
    Multi.update_all(
      multi,
      :notify_count,
      from(u1 in User,
        where: u1.id == ^user.id
      ),
      inc: [notify_count: inc]
    )
  end

  @spec send_notify({:ok, any}) :: any
  def send_notify({:ok, %{activity: %{id: id, type: _type} = _activity}} = ris) do
    NotifyJob.enqueue(:activity, id)

    ris
  end

  def send_notify(%Activity{id: id}), do: NotifyJob.enqueue(:activity, id)

  def send_notify(ris), do: ris

  @spec send_notify(User.t(), Activity.t()) :: :ok | :error
  def send_notify(%User{type: type}, %Activity{id: id}) do
    if type != Const.user_type_newbie() do
      NotifyJob.enqueue(:activity, id)
    else
      admin_ids = Accounts.get_admin_ids()
      NotifyJob.enqueue(:activity, id, admin_ids)
    end

    :ok
  end

  def send_notify(_, _), do: :error
end

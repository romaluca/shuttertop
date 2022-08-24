defmodule Shuttertop.Follows do
  @moduledoc false
  import Ecto.{Query, Changeset}, warn: false
  require Logger
  require Shuttertop.Constants

  alias Shuttertop.{Activities, Paginator, Repo}
  alias Ecto.Multi
  alias Shuttertop.Accounts.User
  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Follows.{FollowContest, FollowPhoto, FollowUser}
  alias Shuttertop.Posts.TopicUser

  @spec get_follows(User.t()) :: Page.t()
  @spec get_follows(User.t(), map) :: Page.t()
  def get_follows(user, params \\ %{}) do
    # Repo.paginate(
    Paginator.paginate(
      from(u in User,
        inner_join: a in FollowUser,
        on: [user_to_id: u.id],
        where: a.user_id == ^user.id and a.type == ^Const.action_follow_user() and u.is_confirmed,
        order_by: [desc: a.id]
      ),
      params
    )
  end

  @spec get_followers(User.t() | Contest.t()) :: Page.t()
  @spec get_followers(User.t() | Contest.t(), map) :: Page.t()
  def get_followers(element, params \\ %{})

  def get_followers(element, params) do
    query =
      case element do
        %User{} = user ->
          from(u in User,
            inner_join: a in FollowUser,
            on: [user_id: u.id],
            where:
              a.user_to_id == ^user.id and a.type == ^Const.action_follow_user() and
                u.is_confirmed,
            order_by: [desc: a.id]
          )

        %Contest{} = contest ->
          from(u in User,
            inner_join: a in FollowContest,
            on: [user_id: u.id],
            where: a.contest_id == ^contest.id and a.type == ^Const.action_follow_contest(),
            order_by: [desc: a.id]
          )
      end

    # Repo.paginate(query, params)
    Paginator.paginate(query, params)
  end

  @spec add(User.t() | Contest.t(), User.t()) :: any
  def add(%User{} = user, %User{} = current_user) when current_user.id == user.id do
    {:error, "follow_user same user"}
  end

  def add(%User{} = user, %User{} = current_user) do
    Multi.new()
    |> multi_create(%FollowUser{
      user_id: current_user.id,
      user_to_id: user.id
    })
    |> multi_update_follows_user(user, 1, true, 1, 3)
    |> multi_update_followers_user(current_user, 1)
    |> Repo.transaction()
    |> case do
      {:ok, activity} = ris ->
        Activities.send_notify(ris)
        {:ok, %User{user | activities_to: [activity], followers_count: user.followers_count + 1}}

      ris ->
        ris
    end
  end

  def add(%Contest{} = contest, current_user) do
    execute_notify = contest.user_id != current_user.id

    activity = %FollowContest{
      user_id: current_user.id,
      user_to_id: contest.user_id,
      contest_id: contest.id
    }

    Multi.new()
    |> multi_create(activity)
    |> multi_update_followers_contest(contest, 1)
    |> multi_update_contest_notify_count(contest, execute_notify, 1, 3)
    |> multi_update_follows_contest(current_user, 1)
    |> multi_insert_contest_topicuser(current_user, contest)
    |> Repo.transaction()
    |> case do
      {:ok, activity} = ris ->
        if execute_notify, do: Activities.send_notify(ris)

        {:ok,
         %Contest{contest | activities: [activity], followers_count: contest.followers_count + 1}}

      ris ->
        ris
    end
  end

  @spec remove(User.t() | Contest.t(), User.t()) :: any
  def remove(%User{} = user, %User{} = current_user)
      when is_nil(user) or user.activities_to == [] or current_user.id == user.id do
    {:error, "follow"}
  end

  def remove(%User{} = user, %User{} = current_user) do
    execute_notify = user.id != current_user.id
    notify_inc = if user.notify_count > 0, do: -1, else: 0

    Multi.new()
    |> multi_delete(%FollowUser{
      user_id: current_user.id,
      type: Const.action_follow_user(),
      user_to_id: user.id
    })
    |> multi_update_follows_user(user, -1, execute_notify, notify_inc, -3)
    |> multi_update_followers_user(current_user, -1)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, %User{user | activities_to: [], followers_count: user.followers_count - 1}}

      ris ->
        ris
    end
  end

  def remove(%Contest{} = contest, %User{}) when contest.activities == [] do
    {:error, "follow"}
  end

  def remove(%Contest{} = contest, %User{} = current_user) do
    execute_notify = contest.user_id != current_user.id
    notify_inc = if contest.user.notify_count > 0, do: -1, else: 0

    Multi.new()
    |> multi_delete(%FollowContest{
      user_id: current_user.id,
      user_to_id: contest.user_id,
      contest_id: contest.id
    })
    |> multi_update_followers_contest(contest, -1)
    |> multi_update_contest_notify_count(contest, execute_notify, notify_inc, -3)
    |> multi_update_follows_contest(current_user, -1)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, %Contest{contest | activities: [], followers_count: contest.followers_count - 1}}

      ris ->
        ris
    end
  end

  @spec multi_delete(Multi.t(), FollowUser.t() | FollowContest.t() | FollowPhoto.t()) :: Multi.t()
  defp multi_delete(multi, %FollowUser{} = activity) do
    query =
      from(a in FollowUser,
        where:
          a.user_id == ^activity.user_id and
            a.type == ^Const.action_follow_user() and
            a.user_to_id == ^activity.user_to_id
      )

    Multi.delete_all(multi, :activity, query)
  end

  defp multi_delete(multi, %FollowContest{} = activity) do
    query =
      from(a in FollowContest,
        where:
          a.user_id == ^activity.user_id and
            a.type == ^Const.action_follow_contest() and
            a.user_to_id == ^activity.user_to_id
      )
      |> where([a], a.contest_id == ^activity.contest_id)

    Multi.delete_all(multi, :activity, query)
  end

  defp multi_delete(multi, %FollowPhoto{} = activity) do
    query =
      from(a in FollowPhoto,
        where:
          a.user_id == ^activity.user_id and
            a.type == ^Const.action_follow_photo() and
            a.user_to_id == ^activity.user_to_id
      )
      |> where([a], a.contest_id == ^activity.contest_id)
      |> where([a], a.photo_id == ^activity.photo_id)

    Multi.delete_all(multi, :activity, query)
  end

  @spec multi_create(Multi.t(), FollowContest.t() | FollowUser.t() | FollowPhoto.t()) :: Multi.t()
  def multi_create(multi, activity) do
    vchangeset =
      case activity do
        %FollowUser{} ->
          FollowUser.changeset(activity)

        %FollowContest{} ->
          FollowContest.changeset(activity)

        %FollowPhoto{} ->
          FollowPhoto.changeset(activity)
      end

    Multi.insert(multi, :activity, vchangeset)
  end

  @spec multi_update_follows_contest(Multi.t(), User.t(), Integer.t()) :: Multi.t()
  defp multi_update_follows_contest(multi, user, inc) do
    Multi.update_all(multi, :follows_contest, from(u in User, where: u.id == ^user.id),
      inc: [follows_contest_count: inc]
    )
  end

  @spec multi_update_followers_contest(Multi.t(), Contest.t(), Integer.t()) :: Multi.t()
  defp multi_update_followers_contest(multi, contest, inc) do
    Multi.run(multi, :contest, fn repo, %{activity: _activity} ->
      repo.update_all(
        from(u in Contest, where: u.id == ^contest.id),
        inc: [followers_count: inc]
      )

      {:ok, {contest.followers_count + inc}}
    end)
  end

  @spec multi_insert_contest_topicuser(Multi.t(), User.t(), Contest.t()) :: Multi.t()
  defp multi_insert_contest_topicuser(multi, user, contest) do
    Multi.run(multi, :topic_user, fn repo, %{} ->
      unless is_nil(contest.topic_id) do
        repo.insert(%TopicUser{user_id: user.id, topic_id: contest.topic_id},
          on_conflict: :nothing
        )
      end

      {:ok, {}}
    end)
  end

  @spec multi_update_contest_notify_count(
          Multi.t(),
          Contest.t(),
          Boolean.t(),
          Integer.t(),
          Integer.t()
        ) :: Multi.t()
  defp multi_update_contest_notify_count(multi, contest, execute_notify, notify_inc, score_inc) do
    Multi.update_all(
      multi,
      :notify_count,
      from(u in User, where: u.id == ^contest.user_id and ^execute_notify),
      inc: [score: score_inc, notify_count: notify_inc]
    )
  end

  @spec multi_update_follows_user(
          Multi.t(),
          User.t(),
          Integer.t(),
          Boolean.t(),
          Integer.t(),
          Integer.t()
        ) :: Multi.t()
  defp multi_update_follows_user(multi, user, inc, execute_notify, notify_inc, score_inc) do
    Multi.run(multi, :user, fn repo, %{activity: _activity} ->
      repo.update_all(
        from(u in User, where: u.id == ^user.id and ^execute_notify),
        inc: [followers_count: inc, score: score_inc, notify_count: notify_inc]
      )

      {:ok, {user.followers_count + inc}}
    end)
  end

  @spec multi_update_followers_user(Multi.t(), User.t(), Integer.t()) :: Multi.t()
  defp multi_update_followers_user(multi, user, inc) do
    Multi.update_all(
      multi,
      :follows_user,
      from(u in User,
        where: u.id == ^user.id
      ),
      inc: [follows_user_count: inc]
    )
  end

  def is_following(%User{} = entity) do
    # Ecto.assoc_loaded?(entity.activities_to) &&
    length(entity.activities_to) > 0
  end

  def is_following(entity) do
    # Ecto.assoc_loaded?(entity.activities) &&
    length(entity.activities) > 0
  end
end

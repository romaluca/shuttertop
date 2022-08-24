defmodule Shuttertop.Posts do
  @moduledoc false
  import Ecto.{Query, Changeset}, warn: false
  require Logger
  require Shuttertop.Constants

  alias Ecto.Multi
  alias Shuttertop.{Paginator, Repo}
  alias Shuttertop.Activities.Activity
  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Posts.{Comment, Topic, TopicUser}
  alias Shuttertop.Accounts.{User, BlockedUser}
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Jobs.NotifyJob

  @spec list_comments() :: Page.t()
  @spec list_comments(map) :: Page.t()
  def list_comments(params \\ %{}) do
    Comment
    |> preload([:user])
    |> Paginator.paginate(params)

    # |> Repo.paginate(params)
  end

  @spec create_topic(map, Integer.t()) :: any
  def create_topic(%{} = params, member_id) do
    changeset = Topic.changeset(%Topic{}, params)

    Multi.new()
    |> Multi.insert(:topic, changeset)
    |> Multi.run(:member, fn repo, %{topic: topic} ->
      if is_nil(topic.photo_id) && !is_nil(topic.contest_id) do
        followers =
          repo.all(
            from(u in User,
              select: %{user_id: u.id, topic_id: type(^topic.id, :integer)},
              inner_join: a in Activity,
              on: [user_id: u.id],
              where:
                a.contest_id == ^topic.contest_id and a.type == ^Const.action_follow_contest()
            )
          )

        Repo.insert_all(TopicUser, followers)
      end

      %TopicUser{user_id: member_id, topic_id: topic.id}
      |> Repo.insert(on_conflict: :nothing)
    end)
    |> Repo.transaction()
  end

  @spec get_topic(Integer.t(), Integer.t()) :: Topic.t() | nil
  def get_topic(user_id, user_to_id) do
    p =
      if user_id > user_to_id do
        %{user_id: user_id, user_to_id: user_to_id}
      else
        %{user_to_id: user_id, user_id: user_to_id}
      end

    Repo.one(
      from(t in Topic,
        preload: [:user, :user_to, :photo, :contest, last_comment: [:user]],
        where: t.user_id == ^p.user_id and t.user_to_id == ^p.user_to_id
      )
    )
  end

  @spec get_topic_id(Integer.t(), Integer.t()) :: Integer.t() | nil
  def get_topic_id(user_id, user_to_id) do
    p =
      if user_id > user_to_id do
        %{user_id: user_id, user_to_id: user_to_id}
      else
        %{user_to_id: user_id, user_id: user_to_id}
      end

    Repo.one(
      from(t in Topic,
        select: t.id,
        where: t.user_id == ^p.user_id and t.user_to_id == ^p.user_to_id
      )
    )
  end

  @spec get_topic(Integer.t()) :: Topic.t() | nil
  def get_topic(id) do
    Repo.one(
      from(t in Topic,
        preload: [:user, :user_to, :contest, last_comment: [:user], photo: [:user]],
        where: t.id == ^id
      )
    )
  end

  @spec list_topics(map, User.t() | nil) :: Page.t()
  def list_topics(%{} = params, current_user) do
    # Repo.paginate(
    Paginator.paginate(
      from(t in Topic,
        inner_join: tu in assoc(t, :topics_users),
        on: tu.user_id == ^current_user.id and t.id == tu.topic_id,
        inner_join: c in assoc(t, :last_comment),
        preload: [
          :user,
          :user_to,
          :contest,
          last_comment: {c, :user},
          photo: [:user],
          topics_users: tu
        ],
        order_by: [desc: t.last_comment_id]
      ),
      params
    )
  end

  @spec create_comment(User.t() | Contest.t() | Photo.t(), binary(), User.t()) ::
          {:ok, %{comment: Comment.t()}} | any
  def create_comment(entity, body, %User{} = user) do
    subscribe_name =
      get_entity_name(entity)
      # TODO
      |> get_subscribe_name(entity.id, user)

    topic = create_entity_topic(entity, user)
    attrs = %{topic_id: topic.id, body: body}

    changeset =
      user
      |> Ecto.build_assoc(:comments)
      |> Comment.changeset(attrs)
      |> comment_update_parent(1, topic)

    result =
      Multi.new()
      |> Multi.insert(:comment, changeset)
      |> Multi.run(:topic, fn repo, %{comment: comment} ->
        topic
        |> Topic.changeset(%{last_comment_id: comment.id})
        |> repo.update()
      end)
      |> Multi.run(:add_member, Shuttertop.Posts, :add_member, [user])
      |> Multi.update_all(
        :update_notify_message_count,
        from(u in User,
          inner_join: tu in TopicUser,
          on: tu.user_id == u.id,
          where: tu.topic_id == ^topic.id and u.id != ^user.id
        ),
        inc: [notify_message_count: 1]
      )
      |> Repo.transaction()

    comment_notify(result, subscribe_name)
  end

  @spec create_entity_topic(Contest.t(), User.t()) :: Topic
  defp create_entity_topic(%Contest{} = contest, _user) do
    if is_nil(contest.topic_id) do
      {:ok, %{topic: i}} = create_topic(%{contest_id: contest.id}, contest.user_id)
      get_topic(i.id)
    else
      get_topic(contest.topic_id)
    end
  end

  @spec create_entity_topic(User.t(), User.t()) :: Topic.t()
  defp create_entity_topic(%User{} = user_to, %User{} = user) do
    params_topic =
      if user.id > user_to.id do
        %{user_id: user.id, user_to_id: user_to.id}
      else
        %{user_to_id: user.id, user_id: user_to.id}
      end

    case get_topic(params_topic.user_id, params_topic.user_to_id) do
      nil ->
        {:ok, %{topic: _inserted}} = create_topic(params_topic, user_to.id)

        get_topic(params_topic.user_id, params_topic.user_to_id)

      t ->
        t
    end
  end

  @spec create_entity_topic(Photo.t(), User.t()) :: Topic.t()
  defp create_entity_topic(%Photo{} = photo, _user) do
    if is_nil(photo.topic_id) do
      {:ok, %{topic: inserted}} =
        create_topic(%{contest_id: photo.contest_id, photo_id: photo.id}, photo.user_id)

      get_topic(inserted.id)
    else
      get_topic(photo.topic_id)
    end
  end

  @spec subscribe_topic(Topic.t(), User.t()) :: any
  def subscribe_topic(%Topic{} = topic, current_user) do
    element_id = get_topic_element_id(topic, current_user)

    get_topic_entity_name(topic)
    |> get_subscribe_name(element_id, current_user)
    |> subscribe_topic()
  end

  def subscribe_topic(topic_name) when is_binary(topic_name) do
    Logger.debug("POSTS subscribe_topic: #{inspect(topic_name)}")
    Phoenix.PubSub.subscribe(Shuttertop.PubSub, topic_name)
  end

  @spec unsubscribe_topic(Topic.t(), User.t()) :: any
  def unsubscribe_topic(topic, current_user) do
    element_id = get_topic_element_id(topic, current_user)

    get_topic_entity_name(topic)
    |> get_subscribe_name(element_id, current_user)
    |> unsubscribe_topic()
  end

  def unsubscribe_topic(topic_name) when is_binary(topic_name) do
    Logger.debug("POSTS unsubscribe_topic: #{inspect(topic_name)}")
    Phoenix.PubSub.unsubscribe(Shuttertop.PubSub, topic_name)
  end

  @spec comment_notify({:ok, %{comment: Comment.t()}} | any, Topic.t() | any) ::
          {:ok, %{comment: Comment.t()}} | any
  defp comment_notify({:ok, %{comment: comment}} = result, topic) do
    NotifyJob.enqueue(:comment, comment.id)

    user =
      from(u in User,
        select: [:id, :name, :upload, :slug],
        where: u.id == ^comment.user_id
      )
      |> Repo.one()

    comment = Map.put(comment, :user, user)

    Phoenix.PubSub.broadcast(Shuttertop.PubSub, topic, {__MODULE__, :created, comment})

    result
  end

  defp comment_notify(result, _), do: result

  @spec comment_update_parent(Changeset.t(), Integer.t(), Topic.t()) :: Changeset.t()
  defp comment_update_parent(changeset, value, topic) do
    changeset
    |> prepare_changes(fn changeset ->
      cond do
        !is_nil(topic.photo_id) ->
          changeset.repo.update_all(
            from(p in Photo, where: p.id == ^topic.photo_id),
            inc: [comments_count: value],
            set: [topic_id: topic.id]
          )

        !is_nil(topic.contest_id) ->
          changeset.repo.update_all(
            from(c in Contest, where: c.id == ^topic.contest_id),
            inc: [comments_count: value],
            set: [topic_id: topic.id]
          )

        true ->
          changeset
      end

      changeset
    end)
  end

  @spec update_member(Topic.t(), User.t()) :: {integer(), nil | [term()]}
  def update_member(%Topic{} = topic, %User{} = user) do
    Repo.update_all(
      from(p in TopicUser, where: p.topic_id == ^topic.id and p.user_id == ^user.id),
      set: [last_read_at: Timex.now()]
    )
  end

  @spec add_member(Ecto.Repo.t(), %{topic: Topic.t()}, User.t()) :: {:ok, %{}}
  def add_member(repo, %{topic: topic}, user) do
    topic_user =
      case repo.get_by(TopicUser, user_id: user.id, topic_id: topic.id) do
        nil -> %TopicUser{user_id: user.id, topic_id: topic.id}
        topic_user -> topic_user
      end

    _ret =
      topic_user
      |> TopicUser.changeset(%{last_read_at: Timex.now()})
      |> repo.insert_or_update()

    {:ok, %{}}
  end

  @spec get_comment(Integer.t()) :: Comment.t() | nil
  def get_comment(id), do: Comment |> Repo.get(id) |> Repo.preload([:user])

  @spec get_comment!(Integer.t()) :: Comment.t()
  def get_comment!(id), do: Comment |> Repo.get!(id) |> Repo.preload([:user])

  @spec get_comment_by(Keyword.t() | map()) :: Comment.t() | nil
  def get_comment_by(list) do
    Comment
    |> Repo.get_by(list)
    |> Repo.preload([:user])
  end

  @spec update_comment(Changeset.t()) :: {:ok, Comment.t()} | {:error, Ecto.Changeset.t()}
  def update_comment(changeset), do: Repo.update(changeset)

  @spec most_recent_comments(nil | Topic.t(), map, User.t() | nil) :: [] | Page.t()
  @spec most_recent_comments(nil | Topic.t(), map, User.t() | nil, Boolean.t()) :: [] | Page.t()
  def most_recent_comments(topic, params, current_user, update_member \\ false)

  def most_recent_comments(%Topic{} = topic, params, current_user, update_member) do
    if !is_nil(topic.photo_id) || !is_nil(topic.contest_id) ||
         (topic.user_id == current_user.id || topic.user_to_id == current_user.id) do
      if update_member, do: update_member(topic, current_user)

      from(c in Comment, where: c.topic_id == ^topic.id, preload: [:user], order_by: [desc: :id])
      |> filter_blocked_user(current_user)
      |> filter_min_date(params)
      |> Paginator.paginate(params)
    else
      []
    end
  end

  def most_recent_comments(nil, _, _, _), do: []

  @spec get_subscribe_name(binary, integer, User.t() | nil) :: binary()
  def get_subscribe_name(entity, element_id, current_user) do
    cond do
      entity != "user" -> "comments:#{entity}:#{element_id}"
      is_nil(current_user) -> raise "get_subscribe_name: current_user is null"
      current_user.id < element_id -> "comments:user:#{current_user.id}_#{element_id}"
      true -> "comments:user:#{element_id}_#{current_user.id}"
    end
  end

  @spec filter_blocked_user(Query.t(), User.t() | nil) :: Query.t()
  defp filter_blocked_user(query, nil), do: query

  defp filter_blocked_user(query, %User{} = current_user) do
    query
    |> join(:left, [c], blocked in BlockedUser,
      on: blocked.user_id == ^current_user.id and blocked.user_to_id == c.user_id
    )
    |> where([c, blocked], is_nil(blocked.user_id))
  end

  @spec filter_min_date(Query.t(), map | any) :: Query.t()
  defp filter_min_date(query, %{min_date: min_date}) do
    where(query, [p], p.inserted_at < ^min_date)
  end

  defp filter_min_date(query, _), do: query

  def get_topic_element_id(topic, current_user) do
    id = topic.photo_id || topic.contest_id

    cond do
      !is_nil(id) -> id
      topic.user_id != current_user.id -> topic.user_id
      true -> topic.user_to_id
    end
  end

  @spec get_topic_entity_name(binary()) :: binary()
  defp get_topic_entity_name(topic) do
    cond do
      !is_nil(topic.photo) -> "photo"
      !is_nil(topic.contest) -> "contest"
      true -> "user"
    end
  end

  @spec get_entity_name(binary()) :: binary()
  defp get_entity_name(entity) do
    case entity do
      %Photo{} -> "photo"
      %Contest{} -> "contest"
      %User{} -> "user"
    end
  end

  @spec get_entity(binary(), integer()) :: User.t() | Photo.t() | Contest.t()
  def get_entity(entity, id) do
    case entity do
      "photo" -> Repo.get!(Photo, id)
      "contest" -> Repo.get!(Contest, id)
      "user" -> Repo.get!(User, id)
    end
  end
end

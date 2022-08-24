defmodule Shuttertop.Contests do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  require Logger
  require Shuttertop.Constants
  alias Ecto.Multi

  alias Shuttertop.Accounts.{
    User,
    BlockedUser
  }

  alias Shuttertop.{
    Activities,
    Paginator,
    Repo
  }

  alias Shuttertop.Activities.Activity
  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Events.Event
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Jobs.NotifyJob

  @spec get_contest(Integer.t(), nil) :: Contest.t() | nil
  def get_contest(id, nil), do: Contest |> Repo.get(id) |> Repo.preload([:user])

  @spec get_contest!(Integer.t()) :: Contest.t()
  def get_contest!(id), do: Contest |> Repo.get!(id) |> Repo.preload([:user])

  @spec get_contest_by(Keyword.t() | map()) :: Contest.t() | nil
  @spec get_contest_by(Keyword.t() | map(), User.t() | nil) :: Contest.t() | nil
  @spec get_contest_by(Keyword.t() | map(), User.t() | nil, map) :: Contest.t() | nil
  def get_contest_by(list, current_user \\ nil, params \\ %{}) do
    current_user
    |> contests_query(params)
    |> Repo.get_by(list)
  end

  @spec get_contest_by!(Keyword.t() | map) :: Contest.t()
  @spec get_contest_by!(Keyword.t() | map, User.t() | nil) :: Contest.t()
  @spec get_contest_by!(Keyword.t() | map, User.t() | nil, map) :: Contest.t()
  def get_contest_by!(list, current_user \\ nil, params \\ %{}) do
    current_user
    |> contests_query(params)
    |> Repo.get_by!(list)
  end

  @spec update_contest(Changeset.t()) :: {:ok, Contest.t()} | {:error, Changeset.t()}
  def update_contest(changeset), do: Repo.update(changeset)

  @spec is_contest_expired?(Contest.t()) :: boolean | {:error, any}
  def is_contest_expired?(contest) do
    Timex.before?(contest.expiry_at, Timex.now())
  end

  def count_contests(), do: Repo.one(from(c in Contest, select: count(c.id)))

  @spec get_contests(map) :: Contest.t() | [Contest.t()] | any
  @spec get_contests(map, nil | User.t()) :: Contest.t() | [Contest.t()] | any
  def get_contests(%{} = params, current_user \\ nil) do
    cond do
      !is_nil(params[:limit]) ->
        current_user
        |> contests_query(params)
        |> limit(^params.limit)
        |> Repo.all()

      !is_nil(params[:one]) ->
        current_user
        |> contests_query(params)
        |> limit(1)
        |> Repo.one()

      true ->
        current_user
        |> contests_query(params)
        |> Paginator.paginate(params)

        # |> Repo.paginate(params)
    end
  end

  @spec contests_query(User.t() | nil, map) :: Query.t()
  defp contests_query(current_user, params) do
    current_user
    |> contests_current_user(params[:following])
    |> contests_join_event_week(params, current_user)
    |> contests_filter_by_params(params |> Enum.to_list())
  end

  @spec contests_filter_by_params(Query.t(), list()) :: Query.t()
  def contests_filter_by_params(query, params) do
    Enum.reduce(params, query, fn
      {:user_id, user_id}, query ->
        filter_user(query, user_id)

      {:category_id, category_id}, query ->
        filter_category(query, category_id)

      {:search, search}, query ->
        filter_search(query, search)

      {:not_expired, _not_expired}, query ->
        contests_filter_expired(query, false)

      {:joined, user_id}, query ->
        contests_joined(query, user_id)

      # {:following, user_id}, query ->
      #  contests_following(query, user_id)

      {:expired, expired}, query ->
        contests_filter_expired(query, expired)

      {:order, order}, query ->
        contests_order(query, order)

      _, query ->
        query
    end)
  end

  @spec create_contest(User.t() | nil) :: {:ok, Contest.t()} | any
  @spec create_contest(map, User.t() | nil) :: {:ok, Contest.t()} | any
  def create_contest(attrs \\ %{}, user) do
    changeset =
      user
      |> Ecto.build_assoc(:contests, start_at: DateTime.truncate(DateTime.utc_now(), :second))
      |> Contest.changeset(attrs)
      |> check_contest_edition()
      |> generate_contest_slug()
      |> update_contest_parent(1)

    Multi.new()
    |> Multi.insert(:contest, changeset)
    |> Ecto.Multi.run(:activity, fn repo, %{contest: contest} ->
      repo.insert(%Activity{
        user_id: user.id,
        contest_id: contest.id,
        type: Const.action_contest_created()
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{contest: contest, activity: activity}} ->
        Activities.send_notify(user, activity)
        {:ok, %Contest{contest | user: user, activities: []}}

      ret ->
        ret
    end
  end

  @spec update_contest(Contest.t(), map) :: {:ok, Contest.t()} | {:error, Changeset.t()}
  def update_contest(%Contest{} = contest, params) do
    contest
    |> Contest.changeset_update(params)
    # |> check_contest_edition TODO controllare in caso di nome modificato
    |> Repo.update()
  end

  @spec delete_contest(Contest.t()) :: any
  def delete_contest(%Contest{photos_count: photos_count}) when photos_count > 0,
    do: {:error, :contest_with_photos}

  def delete_contest(%Contest{} = contest) do
    Multi.new()
    |> Multi.update_all(
      :user_update,
      from(u in User,
        where: u.id == ^contest.user_id
      ),
      inc: [contests_count: -1]
    )
    |> Multi.delete(:delete, contest)
    |> Repo.transaction()
  end

  @spec remove_abuse(Integer.t()) :: Boolean.t()
  def remove_abuse(contest_id) do
    get_contest_by!(id: contest_id)
    |> delete_contest()
    |> case do
      {:ok, _} ->
        true
      ret ->
        Logger.error("remove_abuse: #{inspect(ret)}")
        false
    end
  end

  @spec contests_joined(Query.t(), Integer.t()) :: Query.t()
  defp contests_joined(query, user_id) do
    from(q in query,
      inner_join: p in Photo,
      on: [contest_id: q.id, user_id: ^user_id]
    )
  end

  @spec contests_current_user(User.t() | nil, Boolean.t()) :: Query.t()
  defp contests_current_user(current_user, following) do
    # select = [:id, :name, :slug, :photos_count, :category_id, :start_at, :expiry_at,
    #          :score, :is_expired, :upload, :edition, :followers_count, :photographers_count,
    #          :comments_count, :user_id, user: [:id, :name, :slug, :upload], activities: [:id, :type],
    #          topic: [:id]
    #         ]

    case current_user do
      %User{} ->
        if following do
          from(
            c in Contest,
            inner_join: a in Activity,
            on: [
              contest_id: c.id,
              user_id: ^current_user.id,
              type: ^Const.action_follow_contest()
            ],
            left_join: blocked in BlockedUser,
            on: [
              user_id: ^current_user.id,
              user_to_id: c.user_id
            ],
            preload: [:user, :topic, activities: a],
            where: is_nil(blocked.user_id)
          )
        else
          from(
            c in Contest,
            left_join: a in Activity,
            on: [
              contest_id: c.id,
              user_id: ^current_user.id,
              type: ^Const.action_follow_contest()
            ],
            left_join: blocked in BlockedUser,
            on: [
              user_id: ^current_user.id,
              user_to_id: c.user_id
            ],
            preload: [:user, :topic, activities: a],
            where: is_nil(blocked.user_id)
          )
        end

      _ ->
        from(c in Contest,
          left_join: a in Activity,
          on: [id: 0],
          preload: [:user, :topic, activities: a]
        )
    end
  end

  @spec contests_join_event_week(Query.t(), map, User.t() | nil) :: Query.t()
  defp contests_join_event_week(query, params, current_user) do
    {:ok, week, year} = Event.get_week_year()
    join_type = if is_nil(params[:top_week]), do: :left, else: :inner

    query =
      join(query, join_type, [c], e in Event,
        on:
          e.contest_id == c.id and e.week == ^week and e.year == ^year and
            e.type == ^Const.event_type_top_of_week()
      )

    if is_nil(current_user) do
      preload(query, [_, e], events: e)
    else
      preload(query, [_, _, e], events: e)
    end
  end

  @spec filter_category(Query.t(), Integer.t()) :: Query.t()
  defp filter_category(query, category_id) do
    where(query, [c], c.category_id == ^category_id)
  end

  @spec filter_search(Query.t(), binary) :: Query.t()
  defp filter_search(query, search) do
    where(query, [u], ilike(u.name, ^"%#{search}%"))
  end

  @spec filter_user(Query.t(), Integer.t()) :: Query.t()
  defp filter_user(query, user_id) do
    where(query, [p], p.user_id == ^user_id)
  end

  @spec contests_filter_expired(Query.t(), Boolean.t()) :: Query.t()
  defp contests_filter_expired(query, is_expired) do
    where(query, [c], c.is_expired == ^is_expired)
  end

  @spec contests_order(Query.t(), :top | :expiry | any) :: Query.t()
  defp contests_order(query, order) do
    case order do
      :top ->
        order_by(query, [p], desc: p.photos_count)

      :expiry ->
        order_by(query, [p], desc: p.expiry_at)

      _ ->
        order_by(query, [p], desc: p.id)
    end
  end

  @spec check_contest_edition(Changeset.t()) :: Changeset.t()
  def check_contest_edition(changeset) do
    if changeset.valid? do
      name = get_field(changeset, :name)

      case get_field(changeset, :contest_id) do
        nil ->
          check_contest_duplicate(changeset, name)

        contest_id ->
          check_contest_edition(changeset, contest_id)
      end
    else
      changeset
    end
  end

  @spec check_contest_edition(Changeset.t(), Integer.t()) :: Changeset.t()
  defp check_contest_edition(changeset, contest_id) do
    contest =
      Repo.one(
        from(c in Contest,
          where: c.id == ^contest_id,
          order_by: [desc: c.edition],
          preload: [:user],
          limit: 1
        )
      )

    if is_nil(contest) do
      add_error(changeset, :name, "Contest di riferimento non trovato")
    else
      c_edition =
        Repo.one(
          from(c in Contest,
            where: c.contest_id == ^contest_id,
            order_by: [desc: c.edition],
            preload: [:user],
            limit: 1
          )
        )

      edition = if is_nil(c_edition), do: 1, else: c_edition.edition

      put_change(changeset, :edition, edition + 1)
      |> put_change(:name, contest.name)
    end
  end

  @spec check_contest_duplicate(Changeset.t(), String.t()) :: Changeset.t()
  defp check_contest_duplicate(changeset, name) do
    contest =
      Repo.one(
        from(c in Contest,
          where: ilike(c.name, ^name),
          order_by: [desc: c.edition],
          preload: [:user],
          limit: 1
        )
      )

    id = get_field(changeset, :id)

    if !is_nil(contest) && contest.id != id do
      if contest.is_expired do
        put_change(changeset, :edition, contest.edition + 1)
        |> put_change(:contest_id, contest.contest_id || contest.id)
      else
        add_error(changeset, :name, "Contest in corso", contest: contest)
      end
    else
      changeset
    end
  end

  @spec unique_contest_slug(binary) :: binary
  def unique_contest_slug(title) do
    t = Slugger.slugify_downcase(title)

    if get_contest_by([slug: t], nil) do
      unique_contest_slug("#{t}-#{:rand.uniform(99999)}")
    else
      t
    end
  end

  @spec generate_contest_slug(Changeset.t()) :: Changeset.t()
  defp generate_contest_slug(changeset) do
    case fetch_field(changeset, :slug) do
      {:data, nil} ->
        title_changeset = get_field(changeset, :name)

        if is_nil(title_changeset) do
          changeset
        else
          title =
            if get_field(changeset, :edition) > 1 do
              "#{title_changeset}-v#{get_field(changeset, :edition)}"
            else
              title_changeset
            end

          slug = unique_contest_slug(title)
          put_change(changeset, :slug, slug)
        end

      _ ->
        changeset
    end
  end

  @spec update_contest_parent(Changeset.t(), Integer.t()) :: Changeset.t()
  defp update_contest_parent(changeset, value) do
    changeset
    |> prepare_changes(fn changeset ->
      changeset.data
      |> Ecto.assoc(:user)
      |> changeset.repo.update_all(inc: [contests_count: value])

      changeset
    end)
  end

  @spec check_contests :: any
  def check_contests do
    Logger.debug("----   Check contests  ----")

    contests =
      Repo.all(
        from(c in Contest,
          where: c.expiry_at < ^Timex.now() and not c.is_expired,
          select: [:id, :name, :photographers_count]
        )
      )

    for c <- contests do
      Logger.info("----   Finishing contest: #{c.id} #{c.name}")
      check_contest(c)
    end
  end

  @spec check_contest(Contest.t()) :: any
  def check_contest(%Contest{id: id} = contest) do
    p =
      if contest.photographers_count > 3 do
        from(p in Photo,
          where: p.contest_id == ^id,
          order_by: [desc: p.votes_count, asc: p.id],
          preload: [:user],
          limit: 1
        )
        |> Repo.one()
      else
        nil
      end

    Logger.debug("check_contest - photographers_count: #{contest.photographers_count}")

    if is_nil(p) do
      from(c in Contest, where: c.id == ^id)
      |> Repo.update_all(set: [is_expired: true])

      {:ok, nil}
    else
      from(c in Contest, where: c.id == ^id)
      |> Repo.update_all(set: [winner_id: p.id, is_expired: true])

      {:ok, %{activity: activity}} =
        Multi.new()
        |> Multi.insert(:activity, %Activity{
          user_id: p.user_id,
          photo_id: p.id,
          type: Const.action_win(),
          contest_id: p.contest_id,
          points: 500,
          user_to_id: p.user_id
        })
        |> Multi.update_all(
          :score,
          from(u in User, where: u.id == ^p.user_id),
          inc: [score: 500, notify_count: 1, winner_count: 1]
        )
        |> Repo.transaction()

      if !is_nil(activity.id), do: NotifyJob.enqueue(:activity, activity.id)

      {:ok, %{activity: activity}}
    end
  end

  @spec reset_contest(Integer.t()) :: {:ok}
  def reset_contest(id) do
    Repo.query(
      """
      UPDATE photos as v SET position = s.row, votes_count = 0
        FROM (SELECT row_number() OVER (ORDER BY id) as row, id FROM photos) as s
        WHERE v.id = s.id
        and v.contest_id = $1
      """,
      [id]
    )

    from(p in Activity, where: p.contest_id == ^id and p.type == ^Const.action_vote())
    |> Repo.delete_all()

    {:ok}
  end

  @spec check_contests_positions([Integer.t()] | []) :: {:ok}
  def check_contests_positions([]), do: nil

  def check_contests_positions(ids) do
    for id <- ids do
      Repo.query(
        """
        UPDATE photos as v SET position = s.row
          FROM (SELECT row_number() OVER (ORDER BY votes_count desc, id) as row, id FROM photos where contest_id = $1) as s
          WHERE v.id = s.id
        """,
        [id]
      )
    end

    {:ok}
  end

  @spec check_contest_positions(Integer.t(), Integer.t(), Integer.t()) :: {:ok}
  def check_contest_positions(contest_id, votes_start, votes_end) do
    # Task.async(fn ->
    Repo.query(
      """
      UPDATE photos as v SET position = s.row
        FROM (SELECT row_number() OVER (ORDER BY votes_count desc, id) as row, id FROM photos where contest_id = $1) as s
        WHERE v.id = s.id and v.votes_count BETWEEN $2 AND $3
      """,
      [contest_id, votes_start, votes_end]
    )

    # end)
    {:ok}
  end
end

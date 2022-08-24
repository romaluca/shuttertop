defmodule Shuttertop.Votes do
  @moduledoc false
  import Ecto.{Query, Changeset}, warn: false
  require Logger
  require Shuttertop.Constants

  alias Shuttertop.{Activities, Contests, Paginator, Repo}
  alias Ecto.Multi
  alias Shuttertop.Accounts.User
  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Votes.Vote

  @spec get_recents(Photo.t()) :: Page.t()
  @spec get_recents(Photo.t(), map) :: Page.t()
  def get_recents(photo, params \\ %{}) do
    # Repo.paginate(
    Paginator.paginate(
      from(u in User,
        inner_join: a in Vote,
        on: [user_id: u.id],
        where: a.photo_id == ^photo.id and a.type == ^Const.action_vote(),
        order_by: [desc: a.id]
      ),
      params
    )
  end

  @spec is_voted(Photo.t(), User.t()) :: boolean()
  def is_voted(%Photo{} = photo, %User{} = user) do
    from(v in Vote,
      select: v.id,
      where: v.photo_id == ^photo.id and v.user_id == ^user.id and v.type == ^Const.action_vote()
    )
    |> Repo.one() != nil
  end

  def is_voted(%Photo{}, nil), do: false

  @spec add(Photo.t(), User.t()) :: any
  def add(%Photo{} = photo, %User{} = user) do
    check_vote(photo, :create, user)
    |> multi_create(user)
    |> multi_vote_photo(user, 1)
    |> case do
      {:ok, %{activity: activity, photo: photo, photo_new: {position, votes_count, _, _}}} = ris ->
        if photo.user_id != user.id, do: Activities.send_notify(ris)

        {:ok,
         %Photo{photo | activities: [activity], votes_count: votes_count, position: position}}

      {:error, :photo, error, _} ->
        {:error, error}

      ris ->
        ris
    end
  end

  @spec remove(Photo.t(), User.t()) :: any
  def remove(%Photo{} = photo, %User{} = user) do
    check_vote(photo, :delete, user)
    |> multi_delete(user)
    |> multi_vote_photo(user, -1)
    |> case do
      {:ok, %{photo: photo, photo_new: {position, votes_count, _, _}}} ->
        {:ok, %Photo{photo | activities: [], votes_count: votes_count, position: position}}

      {:error, :photo, error, _} ->
        {:error, error}

      ris ->
        ris
    end
  end

  @spec check_vote(Integer.t(), :create | :delete, User.t()) :: Multi.t()
  defp check_vote(ph, op, %User{} = user) when op == :create or op == :delete do
    voted = is_voted(ph, user)

    Multi.new()
    |> Multi.run(:photo, fn _repo, %{} ->
      can_vote = (op == :create && !voted) || (op == :delete && voted)

      cond do
        !can_vote ->
          {:error, %{status: Const.operation_status_error()}}

        Timex.compare(ph.contest.expiry_at, Timex.now()) < 1 ->
          {:error, %{status: Const.operation_status_contest_expired()}}

        true ->
          # photo = from(p in Photo,
          #  where: p.id == ^ph.id,
          #  select: %Photo{votes_count: p.votes_count, position: p.position})
          # |> Repo.one()
          # %Photo{ph|votes_count: photo.votes_count, position: photo.position}}
          {:ok, ph}
      end
    end)
  end

  @spec vote_random() :: {:ok}
  @spec vote_random(map) :: {:ok}
  def vote_random(params \\ %{}) do
    photos =
      cond do
        params["contest_id"] != nil && params["contest_id"] != "" ->
          Repo.all(
            from(p in Photo, preload: [:contest], where: p.contest_id == ^params["contest_id"])
          )

        params["photo_id"] != nil && params["photo_id"] != "" ->
          Repo.all(from(p in Photo, preload: [:contest], where: p.id == ^params["photo_id"]))

        true ->
          from(p in Photo,
            inner_join: c in Contest,
            on: [id: p.contest_id],
            inner_join: u in User,
            on: [id: p.user_id],
            preload: [contest: c, user: u],
            where: not c.is_expired and u.type != ^Const.user_type_admin(),
            order_by: fragment("RANDOM()"),
            limit: 1
          )
          |> Repo.all()
      end

    max_vote =
      case Integer.parse(params["max_vote"] || "1") do
        {vote, _} -> vote
        _ -> 1
      end

    tasks =
      for p <- photos do
        Task.async(fn ->
          secs = params["sleep"] || Enum.random(5000..20000)
          :timer.sleep(secs)
          m = Enum.random(1..max_vote)

          for _i <- 1..m do
            user =
              from(u in User,
                order_by: fragment("RANDOM()"),
                where: like(u.email, "fake_%@shuttertop.com"),
                limit: 1
              )
              |> Repo.one()

            unless is_nil(user), do: add(p, user)
          end
        end)
      end

    Task.await_many(tasks, 40000)
    Logger.info("random voted!")
    {:ok}
  end

  @spec multi_vote_photo(Multi.t(), User.t(), Integer.t()) :: any
  defp multi_vote_photo(multi, user, incr) do
    multi
    |> multi_vote_others_photo_update(incr)
    |> multi_vote_photo_update(incr)
    |> multi_vote_user_update(user, incr)
    |> Repo.transaction()
  end

  @spec multi_vote_user_update(Multi.t(), User.t(), Integer.t()) :: Multi.t()
  defp multi_vote_user_update(multi, user, incr) do
    Multi.update_all(
      multi,
      :score,
      fn %{photo: photo} ->
        points = if photo.user_id != user.id, do: Const.points_vote() * incr, else: 0

        notify =
          if photo.user_id == user.id || (incr == -1 && photo.user.notify_count < 1),
            do: 0,
            else: incr

        from(u in User,
          where: u.id == ^(photo.user_id || -1),
          update: [inc: [score: ^points, notify_count: ^notify]]
        )
      end,
      []
    )
  end

  @spec multi_vote_photo_update(Multi.t(), Integer.t()) :: Multi.t()
  defp multi_vote_photo_update(multi, incr) do
    Multi.run(multi, :photo_new, fn repo, %{photo: photo, photo_update: {positions, _}} ->
      repo.update_all(
        from(p in Photo, where: p.id == ^photo.id),
        inc: [votes_count: incr, position: positions * incr * -1]
      )

      {:ok,
       {photo.position + positions * incr * -1, photo.votes_count + incr, photo.contest_id,
        photo.user_id}}
    end)
  end

  @spec multi_vote_others_photo_update(Multi.t(), Integer.t()) :: Multi.t()
  defp multi_vote_others_photo_update(multi, incr) do
    Multi.update_all(
      multi,
      :photo_update,
      fn %{photo: photo} ->
        [inf, sup] = Enum.sort([photo.votes_count, photo.votes_count + incr])

        from(p in Photo,
          where:
            p.contest_id == ^photo.contest_id and p.id != ^photo.id and
              ((p.votes_count == ^inf and p.id < ^photo.id) or
                 (p.votes_count == ^sup and p.id > ^photo.id)),
          update: [inc: [position: ^incr]]
        )
      end,
      []
    )
  end

  @spec multi_delete(Multi.t(), User.t()) :: Multi.t()
  defp multi_delete(multi, user) do
    Multi.delete_all(multi, :activity, fn %{photo: photo} ->
      from(a in Vote,
        where:
          a.user_id == ^user.id and
            a.type == ^Const.action_vote() and
            a.user_to_id == ^photo.user_id
      )
      |> where([a], a.contest_id == ^photo.contest_id)
      |> where([a], a.photo_id == ^photo.id)
    end)
  end

  @spec multi_create(Multi.t(), User.t()) :: Multi.t()
  defp multi_create(multi, user) do
    Multi.insert(multi, :activity, fn %{photo: photo} ->
      Vote.changeset(%Vote{
        user_id: user.id,
        user_to_id: photo.user_id,
        contest_id: photo.contest_id,
        photo_id: photo.id
      })
    end)
  end

  @spec check_votes() :: any
  def check_votes() do
    from(p in Photo,
      inner_join: c in Contest,
      on: [id: p.contest_id, is_expired: false],
      left_join: v in Vote,
      on: [photo_id: p.id, type: ^Const.action_vote()],
      group_by: [p.id, p.contest_id],
      having: count(v.id) != p.votes_count,
      select: {p.id, p.contest_id, count(v.id)}
    )
    |> Repo.all()
    |> Enum.map(fn {id, contest_id, votes_count} ->
      from(p in Photo, where: p.id == ^id)
      |> Repo.update_all(set: [votes_count: votes_count])

      contest_id
    end)
    |> Enum.uniq()
    |> Contests.check_contests_positions()
  end
end

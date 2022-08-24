defmodule Shuttertop.Photos do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  require Logger
  require Shuttertop.Constants
  alias Ecto.Multi
  alias Shuttertop.Accounts.{User}
  alias Shuttertop.{Activities, Contests, Repo}
  alias Shuttertop.Activities.Activity
  alias Shuttertop.{Authorizer, Paginator}
  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Uploads.Upload

  @spec get_photo(Integer.t()) :: Photo.t() | nil
  def get_photo(id) do
    Photo |> Repo.get(id) |> Repo.preload([:user, :contest])
  end

  @spec get_photo!(Integer.t()) :: Photo.t()
  def get_photo!(id) do
    Photo |> Repo.get!(id) |> Repo.preload([:user, :contest])
  end

  @spec get_photo_by(Keyword.t() | map) :: Photo.t() | nil
  @spec get_photo_by(Keyword.t() | map, User.t() | nil) :: Photo.t() | nil
  def get_photo_by(list, current_user \\ nil)

  def get_photo_by(list, current_user) do
    current_user
    |> photos_query(%{})
    |> Repo.get_by(list)
  end

  @spec get_photo_by!(Keyword.t() | map) :: Photo.t()
  @spec get_photo_by!(Keyword.t() | map, User.t() | nil) :: Photo.t()
  def get_photo_by!(list, current_user \\ nil)

  def get_photo_by!(list, current_user) do
    current_user
    |> photos_query(%{})
    |> Repo.get_by!(list)
  end

  @spec photos_query(User.t() | nil, map) :: Query.t()
  defp photos_query(current_user, params) do
    current_user
    |> photos_current_user()
    |> photos_filter_by_params(params |> Enum.to_list())
  end

  @spec photos_filter_by_params(Query.t(), list) :: Query.t()
  def photos_filter_by_params(query, params) do
    Enum.reduce(params, query, fn
      {:user_id, user_id}, query ->
        filter_user(query, user_id)

      {:contest_id, contest_id}, query ->
        filter_contest(query, contest_id)

      {:search, search}, query ->
        filter_search(query, search)

      {:wins, wins}, query ->
        photos_filter_wins(query, wins)

      {:not_expired, not_expired}, query ->
        photos_filter_not_expired(query, not_expired)

      {:order, order}, query ->
        photos_order(query, order)

      _, query ->
        query
    end)
  end

  @spec photos_current_user(User.t() | nil) :: Query.t()
  defp photos_current_user(current_user) do
    case current_user do
      %User{} ->
        from(
          p in Photo,
          distinct: true,
          left_join: a in Activity,
          on: [photo_id: p.id, user_id: ^current_user.id, type: ^Const.action_vote()],
          preload: [:user, :contest, :topic, activities: a]
        )

      _ ->
        from(p in Photo,
          left_join: a in Activity,
          on: [id: 0],
          preload: [:user, :contest, :topic, activities: a]
        )
    end
  end

  @spec photos_order(Query.t(), :top_user | :top | any) :: Query.t()
  defp photos_order(query, order) do
    case order do
      :top_user ->
        from(p in query,
          left_join: t in Photo,
          on:
            t.contest_id == p.contest_id and t.user_id == p.user_id and
              (p.votes_count < t.votes_count or (p.votes_count == t.votes_count and p.id > t.id)),
          where: is_nil(t.id),
          order_by: [desc: p.votes_count, asc: p.id]
        )

      :top ->
        order_by(query, [p], desc: p.votes_count, asc: p.id)

      _ ->
        order_by(query, [p], desc: p.id)
    end
  end

  @spec photos_filter_wins(Query.t(), any) :: Query.t()
  defp photos_filter_wins(query, _wins) do
    join(query, :inner, [p], c in Contest, on: p.contest_id == c.id and c.winner_id == p.id)
  end

  @spec photos_filter_not_expired(Query.t(), any) :: Query.t()
  defp photos_filter_not_expired(query, _not_expired) do
    join(query, :inner, [p], c in Contest, on: p.contest_id == c.id and not c.is_expired)
  end

  @spec filter_contest(Query.t(), Integer.t()) :: Query.t()
  defp filter_contest(query, contest_id) do
    where(query, [p], p.contest_id == ^contest_id)
  end

  @spec filter_user(Query.t(), Integer.t()) :: Query.t()
  defp filter_user(query, user_id) do
    where(query, [p], p.user_id == ^user_id)
  end

  @spec filter_search(Query.t(), binary) :: Query.t()
  defp filter_search(query, search) do
    where(query, [u], ilike(u.name, ^"%#{search}%"))
  end

  @spec count_photos_inprogress(Integer.t()) :: Integer.t()
  def count_photos_inprogress(user_id) do
    select = from(u in Photo, select: count(u.id))

    select
    |> filter_user(user_id)
    |> photos_filter_not_expired(true)
    |> Repo.one()
  end

  @spec get_photos(map) :: [Photo.t()] | Photo.t() | any
  @spec get_photos(map, nil | User.t()) :: [Photo.t()] | Photo.t() | any
  def get_photos(%{} = params, current_user \\ nil) do
    cond do
      !is_nil(params[:limit]) ->
        current_user
        |> photos_query(params)
        |> limit(^params.limit)
        |> Repo.all()

      !is_nil(params[:one]) ->
        current_user
        |> photos_query(params)
        |> limit(1)
        |> Repo.one()

      true ->
        current_user
        |> photos_query(params)
        |> Paginator.paginate(params)

        # |> Repo.paginate(params)
    end
  end

  @spec update_photo(Photo.t(), map) :: {:ok, Photo.t()} | {:error, Changeset.t()}
  def update_photo(%Photo{} = photo, params) do
    photo
    |> Photo.changeset(params)
    |> Repo.update()
  end

  @spec delete_photo(Photo.t()) :: any
  def delete_photo(%Photo{} = photo) do
    user_photo_count =
      Repo.one(
        from(p in Photo,
          select: count(p.id),
          where:
            p.contest_id == ^photo.contest_id and
              p.user_id == ^photo.user_id
        )
      )

    inc_photographers = if user_photo_count > 1, do: 0, else: -1

    Multi.new()
    |> Multi.update_all(
      :positions_update,
      from(p in Photo,
        where: p.contest_id == ^photo.contest_id and p.position > ^photo.position
      ),
      inc: [position: -1]
    )
    |> Multi.update_all(
      :contest_update,
      from(c in Contest,
        where: c.id == ^photo.contest_id
      ),
      inc: [photos_count: -1, photographers_count: inc_photographers]
    )
    |> Multi.update_all(
      :user_update,
      from(u in User,
        where: u.id == ^photo.user_id
      ),
      inc: [photos_count: -1]
    )
    |> Multi.delete(:delete, photo)
    |> Repo.transaction()
  end

  @spec remove_abuse(Integer.t()) :: Boolean.t()
  def remove_abuse(photo_id) do
    get_photo_by!(id: photo_id)
    |> delete_photo()
    |> case do
      {:ok, _} ->
        true
      ret ->
        Logger.error("remove_abuse: #{inspect(ret)}")
    end
  end

  @spec expired_validation(Changeset.t(), Contest.t()) :: Changeset.t()
  def expired_validation(changeset, contest) do
    if contest && Contests.is_contest_expired?(contest) do
      add_error(changeset, :base, "Contest terminato")
    else
      changeset
    end
  end

  @spec create_photo(User.t()) :: any
  @spec create_photo(map, User.t()) :: any
  def create_photo(attrs \\ %{}, %User{} = user) do
    if !is_nil(attrs["upload"]) do
      query =
        from(u in Upload,
          where:
            u.name == ^attrs["upload"] and u.type == ^Const.user_type_admin() and
              u.user_id == ^user.id
        )

      upload =
        query
        |> exclude(:select)
        |> limit(1)
        |> select(1)
        |> Repo.one()

      if is_nil(upload), do: _attrs = Map.delete(attrs, "upload")
    end

    contest =
      if attrs["contest_id"],
        do: Contests.get_contest_by([id: attrs["contest_id"]], nil),
        else: nil

    score_user_id =
      if contest && contest.user_id != user.id do
        contest.user_id
      else
        -1
      end

    changeset =
      user
      |> Ecto.build_assoc(:photos,
        position: if(contest, do: contest.photos_count + 1, else: 0)
      )
      |> Photo.create_changeset(attrs)
      |> expired_validation(contest)
      |> generate_photo_slug(contest, user)
      |> check_photo_metadata()
      |> update_photo_parent(1)

    Multi.new()
    |> Multi.insert(:photo, changeset)
    |> Ecto.Multi.run(:activity, fn repo, %{photo: photo} ->
      repo.insert(%Activity{
        user_id: user.id,
        contest_id: contest.id,
        user_to_id: contest.user_id,
        points: if(user.id != contest.user_id, do: 3, else: 0),
        photo_id: photo.id,
        type: Const.action_joined()
      })
    end)
    |> Multi.update_all(
      :score,
      from(u in User, where: u.id == ^score_user_id),
      inc: [score: 3, notify_count: 1]
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{photo: photo, activity: activity}} ->
        Activities.send_notify(activity)
        {:ok, %Photo{photo | activities: [], user: user, contest: contest}}

      ris ->
        ris
    end
  end

  @spec update_photo_parent(Changeset.t(), Integer.t()) :: Changeset.t()
  defp update_photo_parent(changeset, value) do
    contest_id = get_field(changeset, :contest_id)
    user_id = get_field(changeset, :user_id)

    user_photo_count =
      if !is_nil(contest_id) && !is_nil(user_id) do
        Repo.one(
          from(p in Photo,
            select: count(p.id),
            where:
              p.contest_id == ^contest_id and
                p.user_id == ^user_id
          )
        ) || 0
      else
        0
      end

    inc_photographers = if user_photo_count == 0, do: 1, else: 0

    changeset
    |> prepare_changes(fn changeset ->
      changeset.data
      |> Ecto.assoc(:user)
      |> changeset.repo.update_all(inc: [photos_count: value])

      changeset.repo.update_all(
        from(p in Contest, where: p.id == ^contest_id),
        inc: [photos_count: value, photographers_count: inc_photographers]
      )

      changeset
    end)
  end

  @spec generate_photo_slug(Changeset.t(), Contest.t() | nil, User.t()) :: Changeset.t()
  defp generate_photo_slug(changeset, %Contest{} = contest, user) when contest != nil do
    case fetch_field(changeset, :slug) do
      {:data, nil} ->
        slug = unique_photo_slug({:check, "#{user.name}@#{contest.name}"})
        put_change(changeset, :slug, slug)

      _ ->
        changeset
    end
  end

  defp generate_photo_slug(changeset, _, _), do: changeset

  @spec unique_photo_slug({any, binary}) :: binary
  def unique_photo_slug({_, title}) do
    title = Slugger.slugify_downcase(title)
    exists = get_photo_by(slug: title)

    if exists do
      unique_photo_slug({:error, "#{title}-#{:rand.uniform(99999)}"})
    else
      title
    end
  end

  defp check_photo_metadata(changeset) do
    case fetch_field(changeset, :meta) do
      {:changes, meta} when meta != nil ->
        meta =
          meta
          |> check_metadata(Float, "exposure_time")
          |> check_metadata(Float, "f_number")
          |> check_metadata(Float, "lat")
          |> check_metadata(Float, "lng")
          |> check_metadata(Integer, "photographic_sensitivity")

        put_change(changeset, :meta, meta)

      _ ->
        changeset
    end
  end

  defp check_metadata(meta, module, name) do
    if meta[name] && is_binary(meta[name]) do
      val =
        case module.parse(meta[name]) do
          {i, _} -> i
          _ -> nil
        end

      Map.put(meta, name, val)
    else
      meta
    end
  end

  @spec delete_photo(Integer.t(), User.t()) :: any
  def delete_photo(id, current_user) do
    with photo = get_photo_by!(id: id),
         :ok <- Authorizer.authorize(:delete_photo, current_user, photo) do
      delete_photo(photo)
    end
  end

  @spec get_photo_slide(
          Contest.t() | User.t(),
          :top | :news | any,
          Integer.t(),
          Integer.t(),
          User.t() | nil
        ) :: Integer.t() | nil
  def get_photo_slide(parent, view, id, slide, current_user) do
    order_column =
      if view == :top, do: "photos.votes_count desc, photos.id asc", else: "photos.id desc"

    parent_type =
      case parent do
        %Contest{} -> "contest_id"
        %User{} -> "user_id"
      end

    my =
      if view == :my and !is_nil(current_user),
        do: " AND photos.user_id = #{current_user.id}",
        else: ""

    in_progress =
      if view == :in_progress,
        do:
          "INNER JOIN contests as contest_progress ON NOT contest_progress.is_expired AND contest_progress.id = photos.contest_id",
        else: ""

    case Ecto.Adapters.SQL.query(Shuttertop.Repo, """
           WITH cte AS (
             SELECT photos.id, row_number() OVER (ORDER BY #{order_column})
               FROM photos
               #{in_progress}
               WHERE photos.#{parent_type} = #{parent.id} #{my}
               ORDER BY #{order_column}
           ), current AS (
             SELECT row_number
               FROM cte
             WHERE id = #{id}
           )
           SELECT cte.*
             FROM cte, current
               WHERE cte.row_number - current.row_number = #{slide}
             ORDER BY cte.row_number;
         """) do
      {:ok, %{rows: [[id, _row_number]]}} -> id
      {:ok, %{num_rows: 0}} -> nil
    end
  end
end

alias Shuttertop.Repo
import Ecto.{Query, Changeset}, warn: false
alias Shuttertop.{Photos.Photo, Accounts.User}
alias Shuttertop.{Votes, Photos}
require Logger
contest_id = 1018

n_votes = 3000

Task.async_stream(
  1..n_votes,
  fn _ ->
    x1 = DateTime.utc_now()

    id =
      from(c in Photo,
        select: c.id,
        where: c.contest_id == ^contest_id,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      |> Repo.one!()

    user = from(u in User, order_by: fragment("RANDOM()"), limit: 1) |> Repo.one!()
    photo = Photos.get_photo_by!([id: id], user)

    Votes.add(photo, user)
    |> case do
      {:ok, p} ->
        t = DateTime.diff(DateTime.utc_now(), x1, :millisecond)

        Logger.warn(
          "p: #{photo.id} u: #{user.id} pos #{photo.position} -> #{p.position}  votes #{photo.votes_count} -> #{p.votes_count} time: #{t}"
        )

        p

      _ ->
        nil
    end
  end,
  max_concurrency: 4,
  timeout: :infinity,
  ordered: false
)
|> Stream.run()

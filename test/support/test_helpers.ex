defmodule Shuttertop.TestHelpers do
  alias Shuttertop.Repo
  alias Shuttertop.Accounts.User
  alias Shuttertop.{Accounts, Contests, Photos, Posts, Uploads}
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Constants, as: Const

  require Logger
  require Shuttertop.Constants

  def insert_user(attrs \\ %{}) do
    changes =
      Map.merge(
        %{
          name: "user #{Base.encode16(:crypto.strong_rand_bytes(8))}",
          authorizations: [
            %{"password" => "supersecret", "password_confirmation" => "supersecret"}
          ],
          email: "mail#{Base.encode16(:crypto.strong_rand_bytes(8))}@shuttertop.com"
        },
        attrs
      )

    user =
      %User{}
      |> User.form_registration_changeset(changes)
      |> Ecto.Changeset.cast(%{is_confirmed: true}, [:is_confirmed])
      |> Repo.insert!()

    %User{user | activities_to: []}
  end

  def insert_admin(attrs \\ %{}) do
    changes =
      Map.merge(
        %{
          name: "admin #{Base.encode16(:crypto.strong_rand_bytes(8))}",
          authorizations: [
            %{"password" => "supersecret", "password_confirmation" => "supersecret"}
          ],
          email: "adminmail#{Base.encode16(:crypto.strong_rand_bytes(8))}@shuttertop.com"
        },
        attrs
      )

    %User{}
    |> User.form_registration_changeset(changes)
    |> Ecto.Changeset.cast(%{is_confirmed: true, type: Const.user_type_admin()}, [
      :is_confirmed,
      :type
    ])
    |> Repo.insert!()
  end

  def insert_contest(user, attrs \\ %{}) do
    changes =
      Map.merge(
        %{
          "category_id" => 4,
          "description" => "some content",
          "expiry_at" => Timex.to_datetime(Timex.shift(Timex.today(), days: 300)),
          "name" => "c#{Base.encode16(:crypto.strong_rand_bytes(8))}",
          "upload" => "some content",
          "url" => "some content"
        },
        attrs
      )

    {:ok, contest} = Contests.create_contest(changes, user)
    contest
  end

  def insert_photo(user, contest, attrs \\ %{}) do
    p_name = "p#{Base.encode16(:crypto.strong_rand_bytes(8))}"
    u_name = attrs["upload"] || "u#{Base.encode16(:crypto.strong_rand_bytes(8))}"

    changes =
      Map.merge(%{"contest_id" => contest.id, "name" => p_name, "upload" => u_name}, attrs)

    Uploads.create_upload(
      %{
        contest_id: contest.id,
        expiry_at: Timex.to_datetime(Timex.shift(Timex.today(), days: 600)),
        name: u_name,
        type: 2
      },
      user
    )

    {:ok, photo} = Photos.create_photo(changes, user)

    photo
  end

  def insert_device(user, attrs \\ %{}) do
    {:ok, device} = Accounts.create_device(attrs, user)
    device
  end

  def insert_topic(attrs \\ %{}, member_id) do
    {:ok, %{topic: topic}} = Posts.create_topic(attrs, member_id)
    topic
  end

  def insert_upload(user, attrs \\ %{}) do
    Uploads.create_upload(attrs, user)
  end

  def close_contest(contest) do
    Repo.update!(
      Ecto.Changeset.change(contest,
        expiry_at: Timex.to_datetime(Timex.shift(Timex.today(), days: -3))
      )
    )

    Contests.check_contest(contest)
    Repo.get(Contest, contest.id)
  end

  def slug_path(%Contest{} = contest), do: "#{contest.id}-#{contest.slug}"
  def slug_path(%User{} = user), do: "#{user.id}-#{user.slug}"
  def slug_path(%Photo{} = photo), do: "#{photo.id}-#{photo.slug}"
end

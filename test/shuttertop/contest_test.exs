defmodule Shuttertop.ContestTest do
  use Shuttertop.DataCase

  require Logger

  alias Shuttertop.{Contests, Photos, Votes}
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Accounts.User

  @valid_attrs %{
    category_id: 42,
    description: "some content",
    expiry_at: Timex.to_datetime(Timex.shift(Timex.today(), days: 10)),
    followers_count: 42,
    is_expired: true,
    is_public: true,
    is_visible: true,
    name: "some content",
    photos_count: 42,
    score: 42,
    start_at: Timex.to_datetime(Timex.shift(Timex.today(), days: 0)),
    upload: "some content",
    url: "some content"
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    user = insert_user()
    changeset = Contest.changeset(%Contest{user_id: user.id}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    user = insert_user()
    changeset = Contest.changeset(%Contest{user_id: user.id}, @invalid_attrs)
    refute changeset.valid?
  end

  test "win contest" do
    user1 = insert_user()
    contest = insert_contest(user1)
    _photo1 = insert_photo(user1, contest)
    contest = Repo.get(Contest, contest.id)
    assert contest.photographers_count == 1
    user2 = insert_user()
    photo2 = insert_photo(user2, contest)
    contest = Repo.get(Contest, contest.id)
    assert contest.photographers_count == 2
    user3 = insert_user()
    photo3 = insert_photo(user3, contest)
    contest = Repo.get(Contest, contest.id)
    assert contest.photographers_count == 3
    user4 = insert_user()
    photo4 = insert_photo(user4, contest)
    contest = Repo.get(Contest, contest.id)
    assert contest.photographers_count == 4
    photo5 = insert_photo(user3, contest)
    {status, _data} = Votes.add(photo2, user1)
    assert status == :ok
    {status, _data} = Votes.add(photo2, user2)
    assert status == :ok
    {status, _data} = Votes.add(photo2, user3)
    assert status == :ok
    assert Photos.get_photo_slide(user3, :in_progress, photo5.id, 1, user3) == photo3.id

    Repo.update!(
      Ecto.Changeset.change(contest,
        expiry_at: Timex.to_datetime(Timex.shift(Timex.today(), days: -3))
      )
    )

    Contests.check_contest(contest)
    contest = Repo.get(Contest, contest.id)
    assert contest.photographers_count == 4
    assert contest.is_expired
    assert contest.winner_id == photo2.id
    user1 = Repo.get(User, user1.id)
    assert user1.score == 12
    user3 = Repo.get(User, user3.id)
    assert user3.score == 0
    user2 = Repo.get(User, user2.id)
    assert user2.score == 510
    assert Photos.get_photo_slide(contest, :top, photo4.id, 1, user1) == photo5.id
    assert Photos.get_photo_slide(contest, :news, photo4.id, 1, user1) == photo3.id
    assert Photos.get_photo_slide(user3, :news, photo3.id, 1, user1) == nil
    assert Photos.get_photo_slide(user3, :news, photo3.id, -1, user1) == photo5.id
    assert Photos.get_photo_slide(user3, :in_progress, photo3.id, -1, user3) == nil
    assert Photos.get_photo_slide(user3, :my, photo5.id, 1, user3) == photo3.id
  end
end

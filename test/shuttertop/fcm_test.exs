defmodule Shuttertop.FCMTest do
  use Shuttertop.DataCase
  require Shuttertop.Constants

  alias Shuttertop.{Activities, Follows, Contests, Photos, Posts, Uploads, Votes}
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Constants, as: Const

  require Logger

  defp insert_userdummy_with_device(i) do
    user = insert_user()
    insert_device(user, %{"platform" => "android", "token" => "23432423423423423#{i}"})
    insert_device(user, %{"platform" => "ios", "token" => "23232423423423423#{i}"})
    insert_device(user, %{"platform" => "web", "token" => "23232423423423223#{i}"})

    user
  end

  defp insert_dummy_contest(user) do
    Contests.create_contest(
      %{
        "category_id" => 4,
        "description" => "some content",
        "expiry_at" => Timex.to_datetime(Timex.shift(Timex.today(), days: 300)),
        "name" => "contest bello",
        "url" => "some content"
      },
      user
    )
  end

  defp insert_dummy_photo(user, contest) do
    Uploads.create_upload(
      %{
        contest_id: contest.id,
        expiry_at: Timex.to_datetime(Timex.shift(Timex.today(), days: 600)),
        name: "cazziemazzi.jpg",
        type: 2
      },
      user
    )

    Photos.create_photo(%{"contest_id" => contest.id, "upload" => "cazziemazzi.jpg"}, user)
  end

  test "test fcm activity create contest" do
    user = insert_userdummy_with_device(1)
    {:ok, contest} = insert_dummy_contest(user)
    activity = Activities.get_activity_by(contest_id: contest.id)

    assert_enqueued(
      worker: Shuttertop.Jobs.NotifyJob,
      args: %{id: activity.id, type: "activity", user_ids: []}
    )
  end

  test "test fcm activity create photo" do
    user = insert_userdummy_with_device(1)
    {:ok, contest} = insert_dummy_contest(user)
    {:ok, photo} = insert_dummy_photo(user, contest)
    activity = Activities.get_activity_by(photo_id: photo.id)
    assert_enqueued(worker: Shuttertop.Jobs.NotifyJob, args: %{id: activity.id, type: "activity"})
  end

  test "test fcm activity vote photo" do
    user = insert_userdummy_with_device(1)
    {:ok, contest} = insert_dummy_contest(user)
    {:ok, photo} = insert_dummy_photo(user, contest)
    user2 = insert_userdummy_with_device(2)
    {:ok, photo} = Votes.add(photo, user2)
    activity = Activities.get_activity_by(photo_id: photo.id, user_id: user2.id)
    assert_enqueued(worker: Shuttertop.Jobs.NotifyJob, args: %{id: activity.id, type: "activity"})
  end

  test "test fcm activity contest win" do
    user = insert_userdummy_with_device(1)
    {:ok, contest} = insert_dummy_contest(user)
    {:ok, photo} = insert_dummy_photo(user, contest)
    user2 = insert_userdummy_with_device(2)
    {:ok, _photo2} = insert_dummy_photo(user2, contest)
    user3 = insert_userdummy_with_device(3)
    {:ok, _photo3} = insert_dummy_photo(user3, contest)
    user4 = insert_userdummy_with_device(4)
    {:ok, _photo4} = insert_dummy_photo(user4, contest)
    {:ok, _} = Votes.add(photo, user2)

    Repo.update_all(
      from(c in Contest, where: c.id == ^contest.id),
      set: [expiry_at: Timex.to_datetime(Timex.shift(Timex.today(), days: -3))]
    )

    contest_new =
      Repo.one(
        from(c in Contest,
          where: c.id == ^contest.id,
          select: [:id, :name, :photographers_count]
        )
      )

    {:ok, %{activity: activity}} = Contests.check_contest(contest_new)
    assert_enqueued(worker: Shuttertop.Jobs.NotifyJob, args: %{id: activity.id, type: "activity"})
  end

  test "test fcm activity follow contest" do
    user = insert_userdummy_with_device(1)
    {:ok, contest} = insert_dummy_contest(user)
    user2 = insert_userdummy_with_device(2)
    {:ok, contest} = Follows.add(contest, user2)

    activity =
      Activities.get_activity_by(contest_id: contest.id, type: Const.action_follow_contest())

    assert_enqueued(worker: Shuttertop.Jobs.NotifyJob, args: %{id: activity.id, type: "activity"})
  end

  test "test fcm activity follow user" do
    user = insert_userdummy_with_device(1)
    user2 = insert_userdummy_with_device(2)
    {:ok, user} = Follows.add(user, user2)
    activity = Activities.get_activity_by(user_to_id: user.id, type: Const.action_follow_user())
    assert_enqueued(worker: Shuttertop.Jobs.NotifyJob, args: %{id: activity.id, type: "activity"})
  end

  test "test fcm activity create contest comment" do
    user = insert_userdummy_with_device(1)
    {:ok, contest} = insert_dummy_contest(user)
    user2 = insert_userdummy_with_device(2)

    {:ok, %{comment: comment}} = Posts.create_comment(contest, "commento contest!", user2)

    assert_enqueued(worker: Shuttertop.Jobs.NotifyJob, args: %{id: comment.id, type: "comment"})
  end

  test "test fcm activity create photo comment" do
    user = insert_userdummy_with_device(1)
    {:ok, contest} = insert_dummy_contest(user)
    {:ok, photo} = insert_dummy_photo(user, contest)
    user2 = insert_userdummy_with_device(2)

    {:ok, %{comment: comment}} = Posts.create_comment(photo, "commento photo!", user2)

    assert_enqueued(worker: Shuttertop.Jobs.NotifyJob, args: %{id: comment.id, type: "comment"})
  end

  test "test fcm activity create user comment" do
    user = insert_userdummy_with_device(1)
    user2 = insert_userdummy_with_device(2)

    {:ok, %{comment: comment}} = Posts.create_comment(user, "commento user!", user2)

    assert_enqueued(worker: Shuttertop.Jobs.NotifyJob, args: %{id: comment.id, type: "comment"})
  end

  test "test fcm with invalid data" do
    refute_enqueued(worker: Shuttertop.Jobs.NotifyJob, args: %{activity_id: 10})
  end
end

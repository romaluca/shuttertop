defmodule Shuttertop.Jobs.UserMailerJobTest do
  use Shuttertop.DataCase, async: true

  import Swoosh.TestAssertions

  require Shuttertop.Constants

  alias Shuttertop.Constants, as: Const

  setup do
    user = insert_user()
    {:ok, user: user}
  end

  test "it sends a password recovery mail", %{user: user} do
    Shuttertop.Jobs.UserMailerJob.enqueue_password_recovery(user)
    %{success: 1} = Oban.drain_queue(queue: :mails)
    assert_email_sent(to: {user.name, user.email})
  end

  test "it sends a confirm user mail", %{user: user} do
    Shuttertop.Jobs.UserMailerJob.enqueue_registration_confirm(user)
    %{success: 1} = Oban.drain_queue(queue: :mails)
    assert_email_sent(to: {user.name, user.email})
  end

  test "it sends a contact us mail", %{user: _user} do
    Shuttertop.Jobs.UserMailerJob.enqueue_contact_us("luca", "roma@roma.it", "miao")
    %{success: 1} = Oban.drain_queue(queue: :mails)
    assert_email_sent(to: Const.me())
  end

  test "it sends a report photo mail", %{user: user} do
    contest = insert_contest(user)
    photo = insert_photo(user, contest)
    Shuttertop.Jobs.UserMailerJob.enqueue_report(photo, user, "miao")
    %{success: 1} = Oban.drain_queue(queue: :mails)
    assert_email_sent(to: Const.me())
  end

  test "it sends a report contest mail", %{user: user} do
    contest = insert_contest(user)
    Shuttertop.Jobs.UserMailerJob.enqueue_report(contest, user, "miao")
    %{success: 1} = Oban.drain_queue(queue: :mails)
    assert_email_sent(to: Const.me())
  end

  test "it sends a invitation mail", %{user: user} do
    to = "prova@prova.it"
    Shuttertop.Jobs.UserMailerJob.enqueue_invitation(user, to)
    %{success: 1} = Oban.drain_queue(queue: :mails)
    assert_email_sent(to: to)
  end
end

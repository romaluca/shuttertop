defmodule Shuttertop.Jobs.UserMailerJob do
  use Oban.Worker, queue: :mails, max_attempts: 5

  require Logger

  alias Shuttertop.Accounts
  alias Shuttertop.Accounts.User
  alias Shuttertop.{Contests, Photos}
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo
  alias ShuttertopWeb.UserMailer

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok
  def perform(%Oban.Job{args: %{"user_id" => id, "type" => "registration_confirm"}}) do
    user = Accounts.get_user!(id)
    a = Accounts.get_authorization_by!(provider: "identity", user_id: id)

    user
    |> UserMailer.registration_confirm(a.recovery_token)
    |> Shuttertop.Mailer.deliver!()

    :ok
  end

  def perform(%Oban.Job{args: %{"user_id" => id, "type" => "password_recovery"}}) do
    user = Accounts.get_user!(id)
    a = Accounts.get_authorization_by!(provider: "identity", user_id: id)

    user
    |> UserMailer.password_recovery(a.recovery_token)
    |> Shuttertop.Mailer.deliver!()

    :ok
  end

  def perform(%Oban.Job{
        args: %{"name" => name, "mail" => mail, "message" => message, "type" => "contact_us"}
      }) do
    UserMailer.contact_us(name, mail, message)
    |> Shuttertop.Mailer.deliver!()

    :ok
  end

  def perform(%Oban.Job{
        args: %{
          "contest_id" => contest_id,
          "user_id" => user_id,
          "message" => message,
          "type" => "report"
        }
      }) do
    user = Accounts.get_user!(user_id)
    contest = Contests.get_contest!(contest_id)

    UserMailer.report(contest, user, message)
    |> Shuttertop.Mailer.deliver!()

    :ok
  end

  def perform(%Oban.Job{
        args: %{
          "photo_id" => photo_id,
          "user_id" => user_id,
          "message" => message,
          "type" => "report"
        }
      }) do
    user = Accounts.get_user!(user_id)
    photo = Photos.get_photo!(photo_id)

    UserMailer.report(photo, user, message)
    |> Shuttertop.Mailer.deliver!()

    :ok
  end

  def perform(%Oban.Job{args: %{"user_id" => user_id, "email" => email, "type" => "invitation"}}) do
    user = Accounts.get_user!(user_id)

    UserMailer.invitation(user, email)
    |> Shuttertop.Mailer.deliver!()

    :ok
  end

  def perform(%Oban.Job{args: %{"contest_id" => contest_id, "type" => "contest_week"}}) do
    contest = Contests.get_contest!(contest_id)

    for lang <- ["en", "it"] do
      offset = 0
      send_contest_week(lang, offset, contest)
    end

    :ok
  end

  @spec send_contest_week(binary(), integer(), Contest.t()) :: any
  defp send_contest_week(lang, offset, contest) do
    users = Accounts.get_users_nofication_mail_by_lang(lang, 300, offset, contest.user_id)
    tot = Enum.count(users)

    if tot > 0 do
      UserMailer.contest_week(contest, lang, users)
      |> Shuttertop.Mailer.deliver!()
    end

    if tot == 300, do: send_contest_week(lang, offset + 300, contest)
  end

  @spec enqueue_registration_confirm(User.t()) :: any
  def enqueue_registration_confirm(%User{} = user) do
    %{"user_id" => user.id, "type" => "registration_confirm"}
    |> Shuttertop.Jobs.UserMailerJob.new()
    |> Oban.insert!()
  end

  @spec enqueue_password_recovery(User.t()) :: any
  def enqueue_password_recovery(%User{} = user) do
    %{"user_id" => user.id, "type" => "password_recovery"}
    |> Shuttertop.Jobs.UserMailerJob.new()
    |> Oban.insert!()
  end

  @spec enqueue_contact_us(binary, binary, binary) :: any
  def enqueue_contact_us(name, mail, message) do
    %{"name" => name, "mail" => mail, "message" => message, "type" => "contact_us"}
    |> Shuttertop.Jobs.UserMailerJob.new()
    |> Oban.insert!()
  end

  @spec enqueue_report(Contest.t(), User.t(), binary) :: any
  def enqueue_report(%Contest{} = contest, user, message) do
    %{"contest_id" => contest.id, "user_id" => user.id, "message" => message, "type" => "report"}
    |> Shuttertop.Jobs.UserMailerJob.new()
    |> Oban.insert!()
  end

  @spec enqueue_report(Photo.t(), User.t(), binary) :: any
  def enqueue_report(%Photo{} = photo, user, message) do
    %{"photo_id" => photo.id, "user_id" => user.id, "message" => message, "type" => "report"}
    |> Shuttertop.Jobs.UserMailerJob.new()
    |> Oban.insert!()
  end

  @spec enqueue_invitation(User.t(), binary) :: any
  def enqueue_invitation(user, email) do
    %{"user_id" => user.id, "email" => email, "type" => "invitation"}
    |> Shuttertop.Jobs.UserMailerJob.new()
    |> Oban.insert!()
  end

  @spec enqueue_contest_week(Contest.t()) :: any
  def enqueue_contest_week(contest) do
    %{"contest_id" => contest.id, "type" => "contest_week"}
    |> Shuttertop.Jobs.UserMailerJob.new()
    |> Oban.insert!()
  end
end

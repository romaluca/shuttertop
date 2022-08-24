defmodule ShuttertopWeb.UserMailer do
  use Phoenix.Swoosh,
    view: ShuttertopWeb.UserMailerView,
    layout: {ShuttertopWeb.LayoutEmailView, :email}

  import ShuttertopWeb.Gettext

  require Logger
  require Shuttertop.Constants

  alias Shuttertop.Accounts.User
  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo

  @from {"Shuttertop", "info@shuttertop.com"}

  defp host_url do
    if Application.get_env(:shuttertop, :environment) == :dev do
      "http://localhost:8080"
    else
      "https://shuttertop.com"
    end
  end

  @spec registration_confirm(User.t(), binary) :: any
  def registration_confirm(user, token) do
    registration_confirm_url = "#{host_url()}/registration_confirm"
    Gettext.put_locale(ShuttertopWeb.Gettext, user.language)
    params = URI.encode_query(%{email: user.email, token: token})
    url = "#{registration_confirm_url}?#{params}"
    subject = gettext("Completa la registrazione")

    new()
    |> to({user.name, user.email})
    |> from(@from)
    |> subject("Shuttertop - #{subject}")
    |> render_body(:registration_confirm, %{username: user.name, url: url, subject: subject})
  end

  @spec password_recovery(User.t(), binary()) :: any
  def password_recovery(user, token) do
    password_recovery_url = "#{host_url()}/another_life"
    Gettext.put_locale(ShuttertopWeb.Gettext, user.language)
    params = URI.encode_query(%{email: user.email, token: token})
    url = "#{password_recovery_url}?#{params}"
    subject = gettext("Recuperati su Shuttertop.com")

    new()
    |> to({user.name, user.email})
    |> from(@from)
    |> subject("Shuttertop - #{subject}")
    |> render_body(:password_recovery, %{username: user.name, url: url, subject: subject})
  end

  @spec invitation(User.t(), binary()) :: any
  def invitation(user, to) do
    Gettext.put_locale(ShuttertopWeb.Gettext, user.language)
    subject = gettext("%{from} ti ha inviato un invito", from: user.name)

    new()
    |> to(to)
    |> from(@from)
    |> subject("Shuttertop - #{subject}")
    |> render_body(:invitation, %{from: user.name, subject: subject})
  end

  @spec contact_us(binary, binary, binary) :: any
  def contact_us(name, email_address, message) do
    subject = "#{name} ti ha scritto!"

    try do
      p =
        new()
        |> to(Const.me())
        |> from({"Shuttertop", "info@shuttertop.com"})
        |> subject("Shuttertop - #{subject}")
        |> render_body(:contact_us, %{
          message: message,
          name: name,
          subject: subject,
          email_address: email_address
        })

      p
    rescue
      e -> Logger.error(inspect(e))
    end
  end

  @spec report(Contest.t(), User.t(), binary()) :: any
  def report(%Contest{} = contest, %User{} = user, message) do
    url = "#{host_url()}/contests/#{contest.id}-#{contest.slug}"
    subject = "Segnalazione contest: #{contest.name} - #{contest.id}"

    new()
    |> to(Const.me())
    |> from({user.name, user.email})
    |> subject("Shuttertop - #{subject}")
    |> render_body(:report, %{url: url, message: message, subject: subject})
  end

  @spec report(Photo.t(), User.t(), binary()) :: any
  def report(%Photo{} = photo, %User{} = user, message) do
    url = "#{host_url()}/photos/#{photo.id}-#{photo.slug}"
    subject = "Segnalazione foto: #{photo.slug} - #{photo.id}"

    new()
    |> to(Const.me())
    |> from({user.name, user.email})
    |> subject("Shuttertop - #{subject}")
    |> render_body(:report, %{url: url, message: message, subject: subject})
  end

  @spec send_mail(binary(), binary(), binary()) :: Swoosh.Email.t()
  def send_mail(email, subject, message) do
    new()
    |> to(email)
    |> from({"Shuttertop", "info@shuttertop.com"})
    |> subject(subject)
    |> render_body(:send_mail, %{message: message, subject: subject})
  end

  @spec contest_week(Contest.t(), binary(), [User.t()]) :: any
  def contest_week(contest, lang, users) do
    Gettext.put_locale(ShuttertopWeb.Gettext, lang)
    url = "#{host_url()}/contests/#{contest.id}-#{contest.slug}"
    subject = gettext("Contest della settimana")

    cover =
      if is_nil(contest.upload) do
        nil
      else
        "https://img.shuttertop.com/1200#{lang}628/#{contest.upload}"
      end

    new()
    |> bcc(users)
    |> from({"Shuttertop", "info@shuttertop.com"})
    |> subject("Shuttertop - #{subject}")
    |> render_body(:contest_week, %{
      from: contest.user.name,
      url: url,
      cover: cover,
      contest_name: contest.name,
      subject: subject
    })
  end
end

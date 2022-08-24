defmodule ShuttertopWeb.ViewHelpers do
  @moduledoc false
  use Phoenix.HTML

  require ShuttertopWeb.Gettext, as: GettextWeb
  require Logger
  require Shuttertop.Constants

  alias Shuttertop.Accounts
  alias Shuttertop.Accounts.User
  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Guardian.Plug, as: GuardianPlug

  def site_url, do: Const.site_url()
  def site_img_url, do: Const.site_img_url()

  def active_on_current(%{request_path: path}, path), do: "active"
  def active_on_current(_, _), do: ""

  def logged_in?(conn), do: GuardianPlug.authenticated?(conn)
  def current_user(conn), do: GuardianPlug.current_resource(conn)

  def img_empty, do: "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="

  def img_empty(photo) do
    {width, height} =
      if is_nil(photo.width) || is_nil(photo.height) do
        {600, 600}
      else
        {photo.width, photo.height}
      end

    "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 #{width} #{height}'%3E%3C/svg%3E"
  end

  def upload_url(%User{upload: upload}, size) do
    if upload do
      format =
        case size do
          :normal ->
            ""

          :thumb ->
            "300s300/"

          :thumb_small ->
            "70s70/"
        end

      # "https://img.shuttertop.com.s3-website-eu-west-1.amazonaws.com/#{format}#{upload}"
      "https://img.shuttertop.com/#{format}#{upload}"
    else
      "https://img.shuttertop.com/no_image/user.png"
    end
  end

  def upload_url(%Contest{upload: upload}, size) do
    if upload do
      format =
        case size do
          :normal ->
            ""

          :medium ->
            "540s300/"

          :thumb ->
            "260s260/"

          :thumb_small ->
            "70s70/"
        end

      "https://img.shuttertop.com/#{format}#{upload}"
    else
      nil
    end
  end

  def upload_url(%Photo{upload: upload}, size) do
    format =
      case size do
        :normal ->
          ""

        :medium ->
          "960x960/"

        :thumb ->
          "500s500/"

        :thumb_small ->
          "260s260/"
      end

    "https://img.shuttertop.com/#{format}#{upload}"
  end

  def upload_url(_, _) do
    "https://img.shuttertop.com/no_image/user.png"
  end

  def upload_url(params), do: upload_url(params, nil)

  def to_iso8601(dt) do
    case Timex.format(dt, "{ISO:Extended:Z}") do
      {:ok, d} -> d
      {_, _} -> ""
    end
  end

  def days_left(expiry_at) do
    Timex.diff(expiry_at, Timex.now(), :days)
  end

  def time_left(expiry_at) do
    t = Timex.diff(expiry_at, Timex.now(), :seconds)

    if t < 0 do
      GettextWeb.gettext("contest terminato")
    else
      h = Kernel.div(t, 3600)
      m = Kernel.div(t - h * 3600, 60)
      s = t - (h * 3600 + m * 60)
      h = h |> Integer.to_string() |> String.pad_leading(2, "0")
      m = m |> Integer.to_string() |> String.pad_leading(2, "0")
      s = s |> Integer.to_string() |> String.pad_leading(2, "0")
      "#{h}:#{m}:#{s}"
    end
  end

  def get_remain(contest) do
    t = Timex.diff(contest.expiry_at, Timex.now(), :seconds)
    d = Timex.diff(contest.expiry_at, Timex.now(), :days)
    h = Kernel.div(t - d * 86_400, 3600)
    m = Kernel.div(t - (h * 3600 + d * 86_400), 60)
    s = t - (h * 3600 + m * 60 + d * 86_400)
    h = h |> Integer.to_string() |> String.pad_leading(2, "0")
    m = m |> Integer.to_string() |> String.pad_leading(2, "0")
    s = s |> Integer.to_string() |> String.pad_leading(2, "0")
    {d, h, m, s, t < 0}
  end

  def get_activities(entity) do
    if Ecto.assoc_loaded?(entity.activities) do
      entity.activities
    else
      []
    end
  end

  def check_activities(%User{} = entity) do
    if Ecto.assoc_loaded?(entity.activities_to) do
      length(entity.activities_to) > 0
    else
      false
    end
  end

  def check_activities(entity) do
    length(get_activities(entity)) > 0
  end

  @spec get_user(atom | %{user: nil | maybe_improper_list | %{__struct__: atom}}, any) :: any
  def get_user(entity, user) do
    if Ecto.assoc_loaded?(entity.user) do
      entity.user
    else
      user
    end
  end

  def get_user_id(%User{} = user), do: user.id

  def get_user_id(nil), do: nil

  def locale do
    Gettext.get_locale(ShuttertopWeb.Gettext)
  end

  def translate(id) do
    Gettext.dgettext(ShuttertopWeb.Gettext, "dynamic", id)
  end

  def is_production?(), do: Application.get_env(:shuttertop, :environment) == :prod

  def get_color(entity) do
    {:ok, s} = Timex.format(entity.inserted_at, "%S", :strftime)
    String.at(s, 0)
  end

  def get_percent(qt, max_value) do
    if max_value == 0 do
      0
    else
      100 * qt / max_value
    end
  end

  def get_country_codes do
    Accounts.get_country_codes()
  end

  def get_country_name(country_id) do
    if !is_nil(country_id) && country_id != "" do
      c = Enum.at(Countries.filter_by(:alpha2, country_id), 0)
      c.name
    else
      GettextWeb.gettext("Del mondo")
    end
  end

  def blank?(nil), do: true
  def blank?(""), do: true
  def blank?(_), do: false

  def is_admin(user), do: !is_nil(user) and user.type == Const.user_type_admin()

  def slug_path(%Contest{} = contest), do: "#{contest.id}-#{contest.slug}"
  def slug_path(%User{} = user), do: "#{user.id}-#{user.slug}"
  def slug_path(%Photo{} = photo), do: "#{photo.id}-#{photo.slug}"
end

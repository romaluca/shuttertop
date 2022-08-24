defmodule Shuttertop.Locale do
  @moduledoc false

  import Plug.Conn

  require Logger

  def init(_opts), do: nil

  def call(conn, opts) do
    locale = conn.params["locale"] || get_user_language(conn) || get_session(conn, :locale)

    if blank?(locale) do
      locale = List.first(extract_locale(conn)) || opts || "en"

      if blank?(locale) do
        conn
      else
        Gettext.put_locale(ShuttertopWeb.Gettext, locale)
        conn |> put_session(:locale, locale)
      end
    else
      Gettext.put_locale(ShuttertopWeb.Gettext, locale)
      conn |> put_session(:locale, locale)
    end
  end

  # defp assign_locale!(conn, value) do
  #  # Apply the locale as a process var and continue
  #  Gettext.put_locale(ShuttertopWeb.Gettext, value)
  #  conn
  #  |> assign(:locale, value)
  # end

  defp get_user_language(conn) do
    case Shuttertop.Guardian.Plug.current_resource(conn) do
      %Shuttertop.Accounts.User{} = user -> user.language
      _ -> nil
    end
  end

  defp extract_locale(conn) do
    loc =
      if blank?(conn.params["locale"]) do
        extract_accept_language(conn)
      else
        [conn.params["locale"] | extract_accept_language(conn)]
      end

    Enum.filter(loc, fn locale ->
      Enum.member?(ShuttertopWeb.Gettext.supported_locales(), locale)
    end)
  end

  defp extract_accept_language(conn) do
    case conn |> get_req_header("accept-language") do
      [value | _] ->
        value
        |> String.split(",")
        |> Enum.map(&parse_language_option/1)
        |> Enum.sort(&(&1.quality > &2.quality))
        |> Enum.map(& &1.tag)

      _ ->
        []
    end
  end

  defp parse_language_option(string) do
    captures =
      ~r/^(?<tag>[\w\-]+)(?:;q=(?<quality>[\d\.]+))?$/i
      |> Regex.named_captures(string)

    quality =
      case Float.parse(captures["quality"] || "1.0") do
        {val, _} -> val
        _ -> 1.0
      end

    %{tag: captures["tag"], quality: quality}
  end

  def blank?(nil), do: true
  def blank?(""), do: true
  def blank?(_), do: false
end

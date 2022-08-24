defmodule ShuttertopWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext),
  your module gains a set of macros for translations, for example:

      import Shuttertop.Gettext

      # Simple translation
      gettext "Here is the string to translate"

      # Plural translation
      ngettext "Here is the string to translate",
               "Here are the strings to translate",
               3

      # Domain-based translation
      dgettext "errors", "Here is the error message to translate"

  See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.
  """
  use Gettext, otp_app: :shuttertop

  def supported_locales do
    known = Gettext.known_locales(ShuttertopWeb.Gettext)
    allowed = config()[:locales]

    known
    |> Enum.into(MapSet.new())
    |> MapSet.intersection(Enum.into(allowed, MapSet.new()))
    |> MapSet.to_list()
  end

  defp config, do: Application.get_env(:shuttertop, __MODULE__)
end

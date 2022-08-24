defmodule ShuttertopWeb.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML

  require Logger

  @doc """
  Generates tag for inlined form input errors.
  """

  def error_tag(%Ecto.Changeset{} = changeset, field) do
    Enum.map(Keyword.get_values(changeset.errors, field), fn error ->
      content_tag(:span, translate_error(error), class: "invalid-feedback")
    end)
  end

  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, translate_error(error),
        class: "invalid-feedback",
        phx_feedback_for: input_id(form, field)
      )
    end)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(ShuttertopWeb.Gettext, "errors", msg, msg, count, opts)
    else
      if contest = opts[:contest] do
        link(Gettext.dgettext(ShuttertopWeb.Gettext, "errors", msg, opts),
          to: "/contests/#{contest.id}-#{contest.slug}"
        )
      else
        Gettext.dgettext(ShuttertopWeb.Gettext, "errors", msg, opts)
      end
    end
  end
end

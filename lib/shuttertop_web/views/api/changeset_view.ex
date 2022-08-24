defmodule ShuttertopWeb.Api.ChangesetView do
  use ShuttertopWeb, :view

  alias Ecto.Changeset, as: EctoChangeset

  @doc """
  Traverses and translates changeset errors.

  See `Ecto.Changeset.traverse_errors/2` and
  `Shuttertop.ErrorHelpers.translate_error/1` for more details.
  """
  def translate_errors(changeset) do
    EctoChangeset.traverse_errors(changeset, &translate_json_error/1)
  end

  def translate_json_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(ShuttertopWeb.Gettext, "errors", msg, msg, count, opts)
    else
      if contest = opts[:contest] do
        [
          Gettext.dgettext(ShuttertopWeb.Gettext, "errors", msg, opts),
          render(ShuttertopWeb.Api.ContestView, "contest.json", contest: contest)
        ]
      else
        Gettext.dgettext(ShuttertopWeb.Gettext, "errors", msg, opts)
      end
    end
  end

  def render("error.json", %{changeset: changeset}) do
    # When encoded, the changeset returns its errors
    # as a JSON object. So we just pass it forward.
    %{errors: translate_errors(changeset)}
  end
end

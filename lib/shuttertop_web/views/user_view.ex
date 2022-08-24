defmodule ShuttertopWeb.UserView do
  use ShuttertopWeb, :view

  def title_bar(:index, _assigns), do: gettext("Classifica")

  def title_bar(:edit, _assigns), do: gettext("Modifica utente")

  def title_bar(:new, _assigns), do: gettext("Registrazione utente")

  def title_bar(_, _), do: nil

  def subtitle_bar(:index, assigns), do: assigns[:page_title]

  def subtitle_bar(_, _), do: nil
end

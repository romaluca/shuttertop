defmodule ShuttertopWeb.ContestView do
  use ShuttertopWeb, :view

  def page_title(:show, assigns) do
    section =
      case assigns[:params]["section"] do
        "activities" ->
          gettext("novità") <> " ‧ "

        "rank" ->
          gettext("classifica") <> " ‧ "

        "details" ->
          gettext("info") <> " ‧ "

        _ ->
          ""
      end

    "#{assigns[:contest].name} ‧ " <>
      section <> gettext("un contest fotografico")
  end

  def page_title(:index, assigns) do
    t =
      cond do
        assigns[:params]["order"] == "top" ->
          gettext("I migliori contest fotografici")

        !is_nil(assigns[:params]["expired"]) ->
          gettext("Contest fotografici terminati")

        true ->
          gettext("Ultimi contest fotografici inseriti")
      end

    category =
      if is_nil(assigns[:params]["category_id"]) do
        ""
      else
        String.capitalize(translate("category.#{assigns[:params]["category_id"]}")) <> ": "
      end

    String.capitalize(category <> t)
  end

  def page_title(:new, assigns) do
    if is_nil(assigns.changeset.data.contest_id) do
      gettext("Nuovo contest")
    else
      "#{assigns.changeset.data.name} · #{gettext("Nuova edizione")}"
    end
  end

  def page_title(_, _) do
    ""
  end

  def title_bar(:index, _assigns), do: gettext("Contest")

  def title_bar(:new, assigns), do: page_title(:new, assigns)

  def title_bar(:edit, _assigns), do: gettext("Modifica contest")

  def title_bar(_, _), do: nil

  def subtitle_bar(:index, assigns), do: page_title(:index, assigns)

  def subtitle_bar(_, _), do: nil
end

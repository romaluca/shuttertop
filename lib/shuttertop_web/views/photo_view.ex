defmodule ShuttertopWeb.PhotoView do
  use ShuttertopWeb, :view

  alias Shuttertop.Accounts.User
  alias Shuttertop.Contests.Contest

  def render("show.json", %{photo: photo}) do
    %{photo: photo_json(photo)}
  end

  @spec photo_json(Photo.t()) :: map()
  def photo_json(photo) do
    %{
      name: photo.name,
      slug: photo.slug,
      position: photo.position,
      upload: photo.upload,
      votes_count: photo.votes_count,
      comments_count: photo.comments_count,
      contest_id: photo.contest_id,
      user_id: photo.user_id,
      inserted_at: photo.inserted_at
    }
  end

  def get_section_name(%Contest{}), do: "contests"
  def get_section_name(%User{}), do: "users"

  # @spec page_title(atom | any(), any()) :: binary
  # def page_title(:show, assigns) do
  #   photo = assigns[:photo]

  #   if is_nil(photo.name) || photo.name == "" do
  #     gettext(
  #       "La foto di %{user} nel contest %{contest}",
  #       user: assigns[:user].name,
  #       contest: assigns[:photo].contest.name
  #     )
  #   else
  #     gettext(
  #       "%{name} di %{user}",
  #       user: assigns[:user].name,
  #       name: assigns[:photo].name
  #     )
  #   end
  # end

  # def page_title(_, _) do
  #   ""
  # end

  # @spec get_photo_subtitle(atom(), atom()) :: binary
  # def get_photo_subtitle(type, order) do
  #   case {type, order} do
  #     {:contest, :news} ->
  #       gettext("Le foto in ordine di inserimento")

  #     {:contest, :top} ->
  #       gettext("La classifica")

  #     {:user, :news} ->
  #       gettext("Le ultime foto inserite")

  #     {:user, :top} ->
  #       gettext("Le foto con più top")

  #     {_, _} ->
  #       ""
  #   end
  # end

  # @spec title_bar(any(), any()) :: nil
  # def title_bar(_, _), do: nil

  # @spec subtitle_bar(any(), any()) :: nil
  # def subtitle_bar(_, _), do: nil
end

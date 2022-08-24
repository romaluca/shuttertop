defmodule ShuttertopWeb.Api.PhotoView do
  use ShuttertopWeb, :view

  def render("index.json", %{photos: photos, total_entries: total_entries}) do
    %{
      photos: render_many(photos, ShuttertopWeb.Api.PhotoView, "photo_basic.json"),
      total_entries: total_entries
    }
  end

  def render("show.json", %{photo: photo, comments: comments, user: user, tops: tops}) do
    %{
      photo: render(ShuttertopWeb.Api.PhotoView, "photo.json", photo: photo),
      comments: render_many(comments, ShuttertopWeb.Api.CommentView, "comment.json"),
      tops: render_many(tops, ShuttertopWeb.Api.UserView, "user_basic.json"),
      user: render(ShuttertopWeb.Api.UserView, "user_basic.json", user: user)
    }
  end

  def render("show.json", %{photo: photo, comments: comments, tops: tops}) do
    %{
      photo: render(ShuttertopWeb.Api.PhotoView, "photo.json", photo: photo),
      comments: render_many(comments, ShuttertopWeb.Api.CommentView, "comment.json"),
      tops: render_many(tops, ShuttertopWeb.Api.UserView, "user_basic.json")
    }
  end

  def render("photo.json", %{photo: photo}) do
    %{
      id: photo.id,
      name: photo.name,
      upload: photo.upload,
      votes_count: photo.votes_count,
      slug: photo.slug,
      model: photo.model,
      f_number: photo.f_number,
      focal_length: photo.focal_length,
      photographic_sensitivity: photo.photographic_sensitivity,
      exposure_time: photo.exposure_time,
      lat: photo.lat,
      meta: photo.meta,
      topic_id: photo.topic_id,
      lng: photo.lng,
      width: photo.width,
      height: photo.height,
      voted: length(get_activities(photo)) > 0,
      position: photo.position,
      comments_count: photo.comments_count,
      inserted_at: photo.inserted_at,
      user:
        if(
          Ecto.assoc_loaded?(photo.user),
          do: render(ShuttertopWeb.Api.UserView, "user_basic.json", user: photo.user),
          else: nil
        ),
      contest:
        if(
          Ecto.assoc_loaded?(photo.contest),
          do: render(ShuttertopWeb.Api.ContestView, "contest_basic.json", contest: photo.contest),
          else: nil
        ),
      is_winner:
        if(Ecto.assoc_loaded?(photo.contest), do: photo.contest.winner_id == photo.id, else: nil)
    }
  end

  def render("photo_basic.json", %{photo: photo}) do
    %{
      id: photo.id,
      name: photo.name,
      upload: photo.upload,
      votes_count: photo.votes_count,
      comments_count: photo.comments_count,
      voted: length(get_activities(photo)) > 0,
      slug: photo.slug,
      topic_id: photo.topic_id,
      width: photo.width,
      height: photo.height,
      position: photo.position,
      user_id: photo.user_id,
      contest_id: photo.contest_id,
      user:
        if(
          Ecto.assoc_loaded?(photo.user),
          do: render(ShuttertopWeb.Api.UserView, "user_basic.json", user: photo.user),
          else: nil
        ),
      is_winner:
        if(Ecto.assoc_loaded?(photo.contest), do: photo.contest.winner_id == photo.id, else: nil)
    }
  end
end

defmodule ShuttertopWeb.Api.UserView do
  use ShuttertopWeb, :view

  require Logger

  def render("index.json", %{users: users, total_entries: total_entries} = params) do
    %{
      users:
        render_many(
          users,
          ShuttertopWeb.Api.UserView,
          if(params["emails"], do: "user_basic.json", else: "user_basic_email.json")
        ),
      total_entries: total_entries
    }
  end

  def render("show.json", %{
        user: user,
        photos: photos,
        contests: contests,
        followers: followers,
        follows: follows,
        best_photo: best_photo
      }) do
    %{
      user: render(ShuttertopWeb.Api.UserView, "user.json", user: user),
      best_photo:
        if(is_nil(best_photo),
          do: nil,
          else: render(ShuttertopWeb.Api.PhotoView, "photo_basic.json", photo: best_photo)
        ),
      photos: render_many(photos, ShuttertopWeb.Api.PhotoView, "photo_basic.json"),
      contests: render_many(contests, ShuttertopWeb.Api.ContestView, "contest_basic.json"),
      follows: render_many(follows, ShuttertopWeb.Api.UserView, "user_basic.json"),
      followers: render_many(followers, ShuttertopWeb.Api.UserView, "user_basic.json")
    }
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      name: user.name,
      winner_count: user.winner_count,
      photos_count: user.photos_count,
      score: user.score,
      slug: user.slug,
      level: user.level,
      type: user.type,
      language: user.language,
      topic_id: user.topic_id,
      in_progress: user.in_progress,
      follows_user_count: user.follows_user_count,
      followers_count: user.followers_count,
      contest_count: user.contests_count,
      upload: user.upload,
      followed: Ecto.assoc_loaded?(user.activities_to) && length(user.activities_to) > 0,
      blocked: Ecto.assoc_loaded?(user.blocked_users) && length(user.blocked_users) > 0
    }
  end

  def render("user_me.json", %{user: user}) do
    %{
      id: user.id,
      name: user.name,
      winner_count: user.winner_count,
      level: user.level,
      photos_count: user.photos_count,
      score: user.score,
      notifies_mobile_disabled: user.notifies_mobile_disabled,
      slug: user.slug,
      topic_id: user.topic_id,
      type: user.type,
      in_progress: user.in_progress,
      language: user.language,
      upload: user.upload
    }
  end

  def render("user_basic_email.json", %{user: user}) do
    %{
      id: user.id,
      email: user.email,
      name: user.name,
      slug: user.slug,
      level: user.level,
      upload: user.upload,
      score: user.score,
      language: user.language,
      topic_id: user.topic_id,
      score_partial: user.score_partial,
      winner_count: user.winner_count,
      photos_count: user.photos_count,
      followed: Ecto.assoc_loaded?(user.activities_to) && length(user.activities_to) > 0,
      blocked: Ecto.assoc_loaded?(user.blocked_users) && length(user.blocked_users) > 0
    }
  end

  def render("user_basic.json", %{user: user}) do
    %{
      id: user.id,
      name: user.name,
      slug: user.slug,
      upload: user.upload,
      score: user.score,
      level: user.level,
      language: user.language,
      topic_id: user.topic_id,
      score_partial: user.score_partial,
      winner_count: user.winner_count,
      photos_count: user.photos_count,
      blocked: Ecto.assoc_loaded?(user.blocked_users) && length(user.blocked_users) > 0
    }
  end
end

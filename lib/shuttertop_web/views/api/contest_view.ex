defmodule ShuttertopWeb.Api.ContestView do
  use ShuttertopWeb, :view

  require Logger

  def render("index.json", %{contests: contests, total_entries: total_entries}) do
    %{
      contests: render_many(contests, ShuttertopWeb.Api.ContestView, "contest_basic.json"),
      total_entries: total_entries
    }
  end

  def render("home.json", %{recents: recents, tops: tops, expired: expired}) do
    %{
      recents: render_many(recents, ShuttertopWeb.Api.ContestView, "contest_basic.json"),
      tops: render_many(tops, ShuttertopWeb.Api.ContestView, "contest_basic.json"),
      expired: render_many(expired, ShuttertopWeb.Api.ContestView, "contest_basic.json")
    }
  end

  def render("show.json", %{
        contest: contest,
        photos: photos,
        total_entries: total_entries
      }) do
    %{
      contest: render(ShuttertopWeb.Api.ContestView, "contest.json", contest: contest),
      photos: render_many(photos, ShuttertopWeb.Api.PhotoView, "photo_basic.json"),
      total_entries: total_entries
    }
  end

  def render("show.json", %{
        contest: contest,
        photos_user: photos_user,
        photos: photos,
        leaders: leaders,
        followers: followers,
        activities: activities,
        comments: comments,
        user: user
      }) do
    %{
      contest: render(ShuttertopWeb.Api.ContestView, "contest.json", contest: contest),
      photos: render_many(photos, ShuttertopWeb.Api.PhotoView, "photo_basic.json"),
      leaders: render_many(leaders, ShuttertopWeb.Api.PhotoView, "photo_basic.json"),
      activities: render_many(activities, ShuttertopWeb.Api.ActivityView, "activity.json"),
      comments: render_many(comments, ShuttertopWeb.Api.CommentView, "comment.json"),
      user: render(ShuttertopWeb.Api.UserView, "user_basic.json", user: user),
      photos_user:
        if(
          photos_user,
          do: render_many(photos_user, ShuttertopWeb.Api.PhotoView, "photo_basic.json"),
          else: nil
        ),
      followers: render_many(followers, ShuttertopWeb.Api.UserView, "user_basic.json")
    }
  end

  def render("contest.json", %{contest: contest}) do
    %{
      id: contest.id,
      name: contest.name,
      slug: contest.slug,
      inserted_at: contest.inserted_at,
      expiry_at: contest.expiry_at,
      comments_count: contest.comments_count,
      category_id: contest.category_id,
      score: contest.score,
      upload: contest.upload,
      edition: contest.edition,
      topic_id: contest.topic_id,
      description: contest.description,
      is_expired: contest.is_expired,
      photos_count: contest.photos_count,
      followers_count: contest.followers_count,
      photographers_count: contest.photographers_count,
      followed: Ecto.assoc_loaded?(contest.activities) && length(contest.activities) > 0,
      user_id: contest.user_id,
      user:
        if(
          Ecto.assoc_loaded?(contest.user),
          do: render(ShuttertopWeb.Api.UserView, "user_basic.json", user: contest.user),
          else: nil
        ),
      winner_id: contest.winner_id,
      winner:
        if(
          Ecto.assoc_loaded?(contest.winner) && !is_nil(contest.winner),
          do: render(ShuttertopWeb.Api.PhotoView, "photo_basic.json", photo: contest.winner),
          else: nil
        )
    }
  end

  def render("contest_basic.json", %{contest: contest}) do
    %{
      id: contest.id,
      name: contest.name,
      slug: contest.slug,
      expiry_at: contest.expiry_at,
      category_id: contest.category_id,
      upload: contest.upload,
      description:
        if(is_nil(contest.description),
          do: nil,
          else: truncate(contest.description, length: 50, omission: "...")
        ),
      inserted_at: contest.inserted_at,
      comments_count: contest.comments_count,
      photos_count: contest.photos_count,
      followers_count: contest.followers_count,
      photographers_count: contest.photographers_count,
      followed: Ecto.assoc_loaded?(contest.activities) && length(contest.activities) > 0,
      user_id: contest.user_id,
      user:
        if(
          Ecto.assoc_loaded?(contest.user),
          do: render(ShuttertopWeb.Api.UserView, "user_basic.json", user: contest.user),
          else: nil
        ),
      topic_id: contest.topic_id,
      is_expired: contest.is_expired
    }
  end

  def render("contest_activity.json", %{contest: contest}) do
    %{
      id: contest.id,
      name: contest.name,
      slug: contest.slug,
      expiry_at: contest.expiry_at,
      category_id: contest.category_id,
      topic_id: contest.topic_id,
      upload: contest.upload,
      inserted_at: contest.inserted_at,
      comments_count: contest.comments_count,
      photos_count: contest.photos_count,
      followers_count: contest.followers_count,
      photographers_count: contest.photographers_count,
      followed: Ecto.assoc_loaded?(contest.activities) && length(contest.activities) > 0,
      user_id: contest.user_id,
      is_expired: contest.is_expired,
      winner_id: contest.winner_id,
      winner:
        if(
          Ecto.assoc_loaded?(contest.winner) && !is_nil(contest.winner),
          do: render(ShuttertopWeb.Api.PhotoView, "photo_basic.json", photo: contest.winner),
          else: nil
        )
    }
  end

  def render("share_params.json", %{contest: contest}) do
    %{
      id: contest.id,
      name: contest.name,
      slug: contest.slug,
      expiry_at: contest.expiry_at,
      user: contest.user.name
    }
  end
end

defmodule ShuttertopWeb.Api.ActivityView do
  use ShuttertopWeb, :view

  def render("index.json", %{activities: activities, total_entries: total_entries, more: more}) do
    %{
      activities: render_many(activities, ShuttertopWeb.Api.ActivityView, "activity.json"),
      total_entries: total_entries,
      more: more
    }
  end

  def render("index.json", %{activities: activities, total_entries: total_entries}) do
    %{
      activities: render_many(activities, ShuttertopWeb.Api.ActivityView, "activity.json"),
      total_entries: total_entries
    }
  end

  def render("activity.json", %{activity: activity}) do
    %{
      id: activity.id,
      points: activity.points,
      inserted_at: activity.inserted_at,
      type: activity.type,
      user:
        if(
          Ecto.assoc_loaded?(activity.user),
          do: render(ShuttertopWeb.Api.UserView, "user_basic.json", user: activity.user),
          else: nil
        ),
      user_to:
        if(
          Ecto.assoc_loaded?(activity.user_to) && !is_nil(activity.user_to),
          do: render(ShuttertopWeb.Api.UserView, "user_basic.json", user: activity.user_to),
          else: nil
        ),
      photo:
        if(
          Ecto.assoc_loaded?(activity.photo) && !is_nil(activity.photo),
          do: render(ShuttertopWeb.Api.PhotoView, "photo_basic.json", photo: activity.photo),
          else: nil
        ),
      contest:
        if(
          Ecto.assoc_loaded?(activity.contest) && !is_nil(activity.contest),
          do:
            render(ShuttertopWeb.Api.ContestView, "contest_activity.json",
              contest: activity.contest
            ),
          else: nil
        )
    }
  end
end

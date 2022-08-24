defmodule ShuttertopWeb.Api.CommentView do
  use ShuttertopWeb, :view

  alias Timex.Timezone, as: TimexTimezone

  require Logger

  def render("index.json", %{comments: comments, total_entries: total_entries}) do
    %{
      comments: render_many(comments, ShuttertopWeb.Api.CommentView, "comment.json"),
      total_entries: total_entries
    }
  end

  def render("comment.json", %{comment: comment}) do
    %{
      id: comment.id,
      topic_id: comment.topic_id,
      body: comment.body,
      inserted_at: TimexTimezone.convert(comment.inserted_at, "Etc/UTC"),
      user:
        if(Ecto.assoc_loaded?(comment.user),
          do: render(ShuttertopWeb.Api.UserView, "user_basic.json", user: comment.user),
          else: nil
        )
    }
  end

  def render("topics.json", %{topics: topics, total_entries: total_entries}) do
    %{
      topics: render_many(topics, ShuttertopWeb.Api.CommentView, "topic.json"),
      total_entries: total_entries
    }
  end

  def render("topic.json", %{comment: topic}) do
    tu = List.first(topic.topics_users)

    %{
      id: topic.id,
      read_at: if(is_nil(tu), do: nil, else: tu.last_read_at),
      last_comment:
        if(
          Ecto.assoc_loaded?(topic.last_comment),
          do: render(ShuttertopWeb.Api.CommentView, "comment.json", comment: topic.last_comment),
          else: nil
        ),
      user:
        if(
          Ecto.assoc_loaded?(topic.user) && !is_nil(topic.user),
          do: render(ShuttertopWeb.Api.UserView, "user_basic.json", user: topic.user),
          else: nil
        ),
      user_to:
        if(
          Ecto.assoc_loaded?(topic.user_to) && !is_nil(topic.user_to),
          do: render(ShuttertopWeb.Api.UserView, "user_basic.json", user: topic.user_to),
          else: nil
        ),
      photo:
        if(
          Ecto.assoc_loaded?(topic.photo) && !is_nil(topic.photo),
          do: render(ShuttertopWeb.Api.PhotoView, "photo_basic.json", photo: topic.photo),
          else: nil
        ),
      contest:
        if(
          Ecto.assoc_loaded?(topic.contest) && !is_nil(topic.contest),
          do: render(ShuttertopWeb.Api.ContestView, "contest_basic.json", contest: topic.contest),
          else: nil
        )
    }
  end
end

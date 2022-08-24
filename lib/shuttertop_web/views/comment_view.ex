defmodule ShuttertopWeb.CommentView do
  use ShuttertopWeb, :view

  def get_topic_path(conn, topic, current_user) do
    cond do
      !is_nil(topic.photo) ->
        Routes.live_path(
          conn,
          ShuttertopWeb.PhotoLive.Slide,
          "contests",
          slug_path(topic.contest),
          "news",
          topic.photo.id
        )

      !is_nil(topic.contest) ->
        Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, slug_path(topic.contest))

      topic.user_id != current_user.id ->
        Routes.live_path(conn, ShuttertopWeb.UserLive.Show, slug_path(topic.user))

      true ->
        Routes.live_path(conn, ShuttertopWeb.UserLive.Show, slug_path(topic.user_to))
    end
  end

  def get_topic_element_id(topic, current_user) do
    id = topic.photo_id || topic.contest_id

    cond do
      !is_nil(id) ->
        id

      topic.user_id != current_user.id ->
        topic.user_id

      true ->
        topic.user_to_id
    end
  end

  def get_topic_element(topic, current_user) do
    ele = topic.photo || topic.contest

    cond do
      !is_nil(ele) ->
        ele

      topic.user_id != current_user.id ->
        topic.user

      true ->
        topic.user_to
    end
  end

  def get_topic_entity(topic) do
    cond do
      !is_nil(topic.photo) ->
        "photo"

      !is_nil(topic.contest) ->
        "contest"

      true ->
        "user"
    end
  end

  def get_topic_name(conn, topic, current_user) do
    cond do
      !is_nil(topic.photo_id) ->
        icon = safe_to_string(icon_tag(conn, "rightArrowIcon", class: "rightArrowIcon"))
        raw("#{topic.photo.user.name} #{icon}  #{topic.contest.name}")

      !is_nil(topic.contest_id) ->
        topic.contest.name

      !is_nil(topic.user_id) && topic.user_id != current_user.id ->
        topic.user.name

      true ->
        topic.user_to.name
    end
  end

  def get_topic_entity_object(topic, current_user) do
    cond do
      !is_nil(topic.photo) ->
        topic.photo

      !is_nil(topic.contest) ->
        topic.contest

      !is_nil(topic.user) && topic.user_id != current_user.id ->
        topic.user

      true ->
        topic.user_to
    end
  end

  def get_topic_last_user(topic, current_user) do
    cond do
      !is_nil(topic.photo) ->
        topic.last_comment.user

      !is_nil(topic.contest) ->
        topic.last_comment.user

      !is_nil(topic.user) && topic.user_id != current_user.id ->
        topic.user

      true ->
        topic.user_to
    end
  end

  def get_topic_icon(topic) do
    cond do
      !is_nil(topic.photo) ->
        "photo"

      !is_nil(topic.contest) ->
        "flag"

      true ->
        "user-circle"
    end
  end
end

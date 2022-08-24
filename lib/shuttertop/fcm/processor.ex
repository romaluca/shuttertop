defmodule Shuttertop.FCM.Processor do
  @moduledoc false
  import Ecto.{Query, Changeset}, warn: false
  require Logger
  require Shuttertop.Constants

  alias Shuttertop.Accounts.{User, Device}
  alias Shuttertop.Activities.Activity
  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Events.Event
  alias Shuttertop.Jobs.UserMailerJob
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Posts.{Comment, TopicUser}

  @spec notify(Event.t() | Activity.t() | Comment.t(), [Integer.t()] | nil) ::
          {:topic | :ids, any, map, map}
  def notify(%Event{contest: contest, type: Const.event_type_top_of_week()}, user_ids) do
    if is_nil(user_ids) do
      UserMailerJob.enqueue_contest_week(contest)

      {:topic, Const.fcm_topic_top_week(), get_top_of_week_data(contest),
       get_top_of_week_param_i18n(contest)}
    else
      {:ids, user_ids, get_top_of_week_data(contest), get_top_of_week_param_i18n(contest)}
    end
  end

  def notify(
        %Activity{contest: contest, user: user, type: Const.action_contest_created()},
        user_ids
      ) do
    if is_nil(user_ids) do
      {:topic, Const.fcm_topic_new_contest(), get_new_contest_data(contest, user),
       get_new_contest_param_i18n(contest, user)}
    else
      {:ids, query_user(user_ids), get_new_contest_data(contest, user),
       get_new_contest_param_i18n(contest, user)}
    end
  end

  def notify(
        %Activity{
          photo: photo,
          type: Const.action_joined(),
          contest: contest,
          user: user,
          user_to: user_to
        },
        user_ids
      ) do
    if !is_nil(user_ids) or user.id != contest.user_id do
      {:ids, query_user(user_ids || [user_to.id]),
       %{
         body: "%{user_name} ha inserito una foto in %{contest_name}",
         type: Const.action_joined(),
         contest_id: contest.id,
         contest_slug: contest.slug,
         user_upload: user.upload,
         photo_id: photo.id,
         photo_slug: photo.slug,
         photo_user_id: photo.user_id
       },
       %{
         contest_name: contest.name,
         user_name: user.name,
         body: true,
         collapse_key: "#{Const.action_joined()}_#{photo.id}"
       }}
    end
  end

  def notify(
        %Activity{photo: photo, user_to: user_to, contest: contest, type: Const.action_win()},
        user_ids
      ) do
    [
      he_won(contest, photo, user_to, user_ids),
      you_win(contest, photo, user_to, user_ids)
    ]
  end

  def notify(
        %Activity{photo: photo, contest: contest, user: user, type: Const.action_vote()},
        user_ids
      ) do
    {:ids, query_user(user_ids || [photo.user_id]),
     %{
       body: "%{user_name} ha votato la tua foto in %{contest_name}",
       type: Const.action_vote(),
       photo_id: photo.id,
       photo_slug: photo.slug,
       user_upload: user.upload,
       photo_user_id: photo.user_id
     },
     %{
       contest_name: contest.name,
       user_name: user.name,
       body: true,
       collapse_key: "#{Const.action_vote()}_#{photo.user_id}_#{photo.id}"
     }}
  end

  def notify(%Activity{user: user, user_to: user_to, type: Const.action_follow_user()}, user_ids) do
    {:ids, query_user(user_ids || [user_to.id]),
     %{
       body: "%{user_name} ti segue",
       type: Const.action_follow_user(),
       user_id: user.id,
       user_slug: user.slug,
       user_upload: user.upload
     },
     %{user_name: user.name, body: true, collapse_key: "#{Const.action_follow_user()}_#{user.id}"}}
  end

  def notify(
        %Activity{user: user, contest: contest, type: Const.action_follow_contest()},
        user_ids
      ) do
    {:ids, query_user(user_ids || [contest.user_id]),
     %{
       body: "%{user_name} segue il tuo contest %{contest_name}",
       type: Const.action_follow_contest(),
       contest_id: contest.id,
       contest_slug: contest.slug,
       user_upload: user.upload,
       contest_user_id: contest.user_id
     },
     %{
       user_name: user.name,
       contest_name: contest.name,
       body: true,
       collapse_key: "#{Const.action_follow_contest()}_#{contest.id}_#{user.id}"
     }}
  end

  def notify(%Comment{} = comment, user_ids) do
    cond do
      !is_nil(comment.topic.photo_id) ->
        notify_comment(:photo, comment, user_ids)

      !is_nil(comment.topic.contest_id) ->
        notify_comment(:contest, comment, user_ids)

      true ->
        notify_comment(:user, comment, user_ids)
    end
  end

  def notify(
        %Activity{user: user, user_to: user_to, type: Const.action_friend_signed()},
        user_ids
      ) do
    {:ids, query_user(user_ids || [user_to.id]),
     %{
       body: "Il tuo amico %{user_name} si è iscritto",
       type: Const.action_friend_signed(),
       user_id: user.id,
       user_slug: user.slug,
       user_upload: user.upload
     },
     %{
       user_name: user.name,
       body: true,
       collapse_key: "#{Const.action_friend_signed()}_#{user.id}"
     }}
  end

  @spec query_user([Integer.t()]) :: any
  defp query_user(user_ids) do
    from(d in Device,
      inner_join: u in User,
      on: [id: d.user_id],
      where: d.user_id in ^user_ids
    )
  end

  @spec he_won(Contest.t(), Photo.t(), User.t(), Integer.t() | nil) :: {:ids, any, map, map}
  defp he_won(%Contest{} = contest, %Photo{} = photo, %User{} = user_to, user_ids) do
    query =
      if is_nil(user_ids) do
        from(d in Device,
          inner_join: u in User,
          on: [id: d.user_id],
          inner_join: p in Photo,
          on: [user_id: u.id],
          where: p.contest_id == ^contest.id and u.id != ^user_to.id
        )
      else
        query_user(user_ids)
      end

    {:ids, query,
     %{
       body: "%{user_name} ha vinto %{contest_name}",
       type: Const.action_win(),
       contest_id: contest.id,
       user_upload: user_to.upload,
       contest_slug: contest.slug,
       contest_user_id: contest.user_id,
       photo_id: photo.id
     },
     %{
       user_name: user_to.name,
       contest_name: contest.name,
       body: true,
       collapse_key: "#{Const.action_win()}_#{photo.id}"
     }}
  end

  @spec you_win(Contest.t(), Photo.t(), User.t(), Integer.t() | nil) :: {:ids, any, map, map}
  defp you_win(%Contest{} = contest, %Photo{} = photo, %User{} = user_to, user_ids) do
    query =
      if is_nil(user_ids) do
        from(d in Device,
          inner_join: u in User,
          on: [id: d.user_id],
          inner_join: p in Photo,
          on: [user_id: u.id],
          where: p.contest_id == ^contest.id and u.id == ^user_to.id
        )
      else
        query_user(user_ids)
      end

    {:ids, query,
     %{
       body: "Hai vinto %{contest_name}",
       type: Const.action_win(),
       contest_id: contest.id,
       contest_slug: contest.slug,
       contest_user_id: contest.user_id,
       photo_id: photo.id
     },
     %{contest_name: contest.name, body: true, collapse_key: "#{Const.action_win()}_#{photo.id}"}}
  end

  @spec notify_comment(:photo | :contest | :user, Comment.t(), Integer.t() | nil) ::
          {:ids, any, map, map}
  defp notify_comment(:photo, %Comment{} = comment, user_ids) do
    query =
      if is_nil(user_ids) do
        from(d in Device,
          inner_join: u in User,
          on: d.user_id == u.id and u.id != ^comment.user.id,
          inner_join: tu in TopicUser,
          on: tu.user_id == u.id and tu.topic_id == ^comment.topic.id
        )
      else
        query_user(user_ids)
      end

    {:ids, query,
     %{
       body: "%{user_name}: %{comment_body}",
       title: "Foto in %{contest_name}",
       type: Const.action_commented(),
       comment: %{
         id: comment.id,
         inserted_at: comment.inserted_at,
         user: %{
           id: comment.user.id,
           name: comment.user.name,
           upload: comment.user.upload,
           slug: comment.user.slug
         },
         body: comment.body
       },
       photo_id: comment.topic.photo_id,
       user_upload: comment.topic.photo.upload,
       photo_slug: comment.topic.photo.slug,
       photo_user_id: comment.topic.photo.user_id
     },
     %{
       contest_name: comment.topic.contest.name,
       user_name: comment.user.name,
       comment_body: comment.body,
       body: true,
       title: true,
       collapse_key: "#{Const.action_commented()}_#{comment.id}"
     }}
  end

  defp notify_comment(:contest, %Comment{} = comment, user_ids) do
    query =
      if is_nil(user_ids) do
        from(d in Device,
          inner_join: u in User,
          on: d.user_id == u.id and u.id != ^comment.user.id,
          inner_join: tu in TopicUser,
          on: tu.user_id == u.id and tu.topic_id == ^comment.topic.id
        )
      else
        query_user(user_ids)
      end

    {:ids, query,
     %{
       body: "#{comment.user.name}: #{comment.body}",
       type: Const.action_contest_commented(),
       title: comment.topic.contest.name,
       user_upload: comment.user.upload,
       contest_slug: comment.topic.contest.slug,
       contest_user_id: comment.topic.contest.user_id,
       contest_id: comment.topic.contest_id,
       comment: %{
         id: comment.id,
         inserted_at: comment.inserted_at,
         user: %{
           id: comment.user.id,
           name: comment.user.name,
           upload: comment.user.upload,
           slug: comment.user.slug
         },
         body: comment.body
       }
     }, %{collapse_key: "#{Const.action_contest_commented()}_#{comment.id}"}}
  end

  defp notify_comment(:user, %Comment{} = comment, user_ids) do
    query =
      if is_nil(user_ids) do
        from(d in Device,
          inner_join: u in User,
          on: d.user_id == u.id and u.id != ^comment.user.id,
          where:
            d.user_id != ^comment.user_id and
              (d.user_id == ^comment.topic.user_to_id or d.user_id == ^comment.topic.user_id)
        )
      else
        query_user(user_ids)
      end

    {:ids, query,
     %{
       body: comment.body,
       type: Const.action_user_commented(),
       title: comment.user.name,
       user_upload: comment.user.upload,
       user_slug: comment.user.slug,
       user_id: comment.user.id,
       comment: %{
         id: comment.id,
         inserted_at: comment.inserted_at,
         topic_id: comment.topic.id,
         user: %{
           id: comment.user.id,
           name: comment.user.name,
           upload: comment.user.upload,
           slug: comment.user.slug
         },
         body: comment.body
       }
     }, %{collapse_key: "#{Const.action_user_commented()}_#{comment.id}"}}
  end

  defp get_new_contest_data(contest, user) do
    %{
      body: "%{user_name} ha creato il contest %{contest_name}",
      type: Const.action_contest_created(),
      contest_id: contest.id,
      contest_slug: contest.slug,
      user_upload: user.upload,
      contest_user_id: user.id,
      user_id: user.id
    }
  end

  defp get_new_contest_param_i18n(contest, user) do
    %{
      contest_name: contest.name,
      user_name: user.name,
      body: true,
      collapse_key: "#{Const.action_contest_created()}_#{contest.id}"
    }
  end

  defp get_top_of_week_param_i18n(contest) do
    %{
      contest_name: contest.name,
      body: true,
      collapse_key: "#{Const.event_type_top_of_week()}_#{contest.id}"
    }
  end

  defp get_top_of_week_data(contest) do
    %{
      body: "Contest della settimana: %{contest_name}",
      type: "#{Const.event_type_top_of_week()}",
      contest_id: contest.id,
      contest_slug: contest.slug,
      contest_user_id: contest.user_id
    }
  end
end

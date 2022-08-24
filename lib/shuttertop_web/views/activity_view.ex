defmodule ShuttertopWeb.ActivityView do
  use ShuttertopWeb, :view

  require Logger
  require Shuttertop.Constants

  alias Shuttertop.Activities.Activity
  alias Shuttertop.Accounts.User
  alias Shuttertop.Constants, as: Const

  def block_type(%Activity{} = activity) do
    if block_type_win?(activity) do
      "win"
    else
      if block_type_photo?(activity), do: "photo", else: "contest"
    end
  end

  def block_type_photo?(%Activity{} = activity) do
    activity.type == Const.action_joined()
  end

  def block_type_win?(%Activity{} = activity) do
    activity.type == Const.action_win()
  end

  def get_activity_object_link(conn, activity, class \\ nil) do
    cond do
      activity.type in [
        Const.action_follow_contest(),
        Const.action_contest_created(),
        Const.action_joined(),
        Const.action_win()
      ] ->
        live_redirect(activity.contest.name,
          to: Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, activity.contest),
          class: class
        )

      activity.type in [
        Const.action_first_avatar(),
        Const.action_signup(),
        Const.action_user_commented(),
        Const.action_friend_signed()
      ] ->
        ""

      activity.type in [
        Const.action_commented(),
        Const.action_vote(),
        Const.action_follow_user()
      ] ->
        live_redirect(activity.user_to.name,
          to: Routes.live_path(conn, ShuttertopWeb.UserLive.Show, slug_path(activity.user_to)),
          class: class
        )
    end
  end

  def get_activity_object(activity, current_user \\ nil) do
    cond do
      activity.type in [
        Const.action_follow_contest(),
        Const.action_contest_created(),
        Const.action_joined(),
        Const.action_win()
      ] ->
        activity.contest.name

      activity.type in [
        Const.action_first_avatar(),
        Const.action_user_commented(),
        Const.action_friend_signed(),
        Const.action_signup()
      ] ->
        ""

      activity.type in [
        Const.action_commented(),
        Const.action_vote(),
        Const.action_follow_user(),
        Const.action_contest_commented()
      ] ->
        cond do
          !is_nil(current_user) && current_user.id == activity.user_to_id ->
            gettext("tu")

          Ecto.assoc_loaded?(activity.recipients) && length(activity.recipients) > 0 ->
            activity.user_to.name

          true ->
            activity.user_to.name
        end
    end
  end

  def get_activity_path(conn, activity) do
    cond do
      activity.type in [
        Const.action_follow_contest(),
        Const.action_contest_created(),
        Const.action_contest_commented(),
        Const.action_win()
      ] ->
        Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, activity.contest)

      activity.type in [Const.action_first_avatar(), Const.action_signup()] ->
        Routes.live_path(conn, ShuttertopWeb.UserLive.Show, slug_path(activity.user))

      activity.type in [
        Const.action_follow_user(),
        Const.action_user_commented(),
        Const.action_friend_signed()
      ] ->
        Routes.live_path(conn, ShuttertopWeb.UserLive.Show, slug_path(activity.user))

      activity.type in [
        Const.action_vote(),
        Const.action_commented(),
        Const.action_joined()
      ] ->
        Routes.live_path(
          conn,
          ShuttertopWeb.PhotoLive.Slide,
          "contests",
          slug_path(activity.contest),
          "news",
          activity.photo.id
        )
    end
  end

  @spec get_activity_text(%Activity{}, %User{}) :: binary
  def get_activity_text(activity, current_user) do
    text =
      case activity.type do
        Const.action_follow_contest() ->
          "%{user_name} segue il tuo contest %{contest_name}"

        Const.action_contest_created() ->
          "%{user_name} ha creato il contest %{contest_name}"

        Const.action_win() ->
          if current_user.id == activity.user.id,
            do: "Hai vinto %{contest_name}",
            else: "%{user_name} ha vinto %{contest_name}"

        Const.action_follow_user() ->
          "%{user_name} ti segue"

        Const.action_friend_signed() ->
          "Il tuo amico %{user_name} si è iscritto"

        Const.action_vote() ->
          "%{user_name} ha votato la tua foto in %{contest_name}"

        Const.action_joined() ->
          "%{user_name} ha inserito una foto in %{contest_name}"

        Const.action_user_commented() ->
          "%{user_name} ti ha scritto"

        _ ->
          nil
      end

    if is_nil(text) do
      "#{activity.type}"
    else
      Gettext.dgettext(ShuttertopWeb.Gettext, "dynamic", text, %{
        user_name: "<b>#{activity.user.name}</b>",
        contest_name:
          if(is_nil(activity.contest), do: nil, else: "<b>#{activity.contest.name}</b>")
      })
    end
  end
end

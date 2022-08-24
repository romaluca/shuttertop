defmodule Shuttertop.Constants do
  @moduledoc false

  use Constants

  define(operation_status_ok, 0)
  define(operation_status_error, 1)
  define(operation_status_contest_expired, 2)
  define(operation_status_contest_inprogress, 3)

  define(action_follow_user, 0)
  define(action_follow_contest, 1)
  define(action_contest_created, 2)
  define(action_first_avatar, 3)
  define(action_commented, 4)
  define(action_joined, 5)
  define(action_signup, 6)
  define(action_vote, 7)
  define(action_win, 8)
  define(action_follow_photo, 9)
  define(action_contest_commented, 10)
  define(action_user_commented, 11)
  define(action_friend_signed, 12)

  define(event_type_top_of_week, 13)

  define(points_vote, 5)
  define(points_first_avatar, 10)
  define(points_follow_contest, 3)
  define(points_follow_user, 0)
  define(points_follow_photo, 0)

  define(action_keys, [
    "action_follow_user",
    "action_follow_contest",
    "action_contest_created",
    "action_first_avatar",
    "action_commented",
    "action_joined",
    "action_signup",
    "action_vote",
    "action_win",
    "action_follow_photo",
    "action_contest_commented",
    "action_user_commented",
    "action_friend_signed"
  ])

  define(user_type_normal, 0)
  define(user_type_tester, 1)
  define(user_type_admin, 2)
  define(user_type_newbie, 3)

  define(fcm_topic_new_contest, "new-contest")
  define(fcm_topic_top_week, "top-week")

  define(site_url, "https://shuttertop.com")
  define(site_img_url, "https://img.shuttertop.com")
  define(me, {"Roma", "romagnoliluca82@gmail.com"})
end

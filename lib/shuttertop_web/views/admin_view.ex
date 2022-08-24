defmodule ShuttertopWeb.AdminView do
  use ShuttertopWeb, :view

  require Shuttertop.Constants

  alias Shuttertop.Accounts.Authorization
  alias Shuttertop.Activities.Activity
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

  def get_provider_url(%Authorization{} = authorization) do
    case authorization.provider do
      "facebook" ->
        "https://facebook.com/profile.php?id=#{authorization.uid}"

      "google" ->
        "https://gmail.googleapis.com/gmail/v1/users/#{authorization.uid}/profile"
    end
  end
end

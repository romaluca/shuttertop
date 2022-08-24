defmodule Shuttertop.Authorizer do
  @moduledoc false

  require Shuttertop.Constants

  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Accounts.User

  def authorize(action, %User{} = _user)
      when action == :create_contest or action == :create_photo,
      do: :ok

  def authorize(:edit_contest, %User{} = user, %Contest{} = contest) do
    if owned_by?(user, contest) || user.type == Const.user_type_admin() do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  def authorize(:delete_contest, %User{} = user, %Contest{} = contest) do
    cond do
      !owned_by?(user, contest) && user.type != Const.user_type_admin() ->
        {:error, :contest_created_by_another_user}

      contest.photos_count > 0 ->
        {:error, :contest_with_photos}

      true ->
        :ok
    end
  end

  def authorize(:edit_photo, %User{} = user, %Photo{} = photo) do
    if owned_by?(user, photo) || user.type == Const.user_type_admin() do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  def authorize(:delete_photo, %User{} = user, %Photo{} = photo) do
    cond do
      !owned_by?(user, photo) && user.type != Const.user_type_admin() ->
        {:error, :unauthorized}

      photo.contest.is_expired ->
        {:error, :terminated}

      true ->
        :ok
    end
  end

  def authorize(:edit_user, %User{} = current_user, %User{} = user) do
    if user.id == current_user.id || current_user.type == Const.user_type_admin() do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  defp owned_by?(%User{} = user, %Contest{} = contest) do
    contest.user_id == user.id
  end

  defp owned_by?(%User{} = user, %Photo{} = photo) do
    photo.user_id == user.id
  end
end

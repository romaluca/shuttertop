defmodule ShuttertopWeb.Api.DeviceController do
  use ShuttertopWeb, :controller

  require Logger
  require Shuttertop.Constants

  alias Shuttertop.Accounts
  alias Shuttertop.Posts.{Comment, Topic}

  alias Shuttertop.Jobs.NotifyJob
  alias Shuttertop.Activities.Activity
  alias Shuttertop.Guardian.Plug
  alias Shuttertop.Repo
  alias Shuttertop.Constants, as: Const

  plug(Guardian.Plug.EnsureAuthenticated when action in [:create, :delete])

  action_fallback(ShuttertopWeb.Api.FallbackController)

  def create(conn, %{"device" => device_params}) do
    current_user = Plug.current_resource(conn)

    with {:ok, device} <- Accounts.create_device(device_params, current_user) do
      conn
      |> put_status(:created)
      |> render("show.json", device: device)
    end
  end

  def get_info(conn, _) do
    min_android_version = Application.get_env(:shuttertop, :min_android_version)
    min_ios_version = Application.get_env(:shuttertop, :min_ios_version)

    Logger.info(
      "min_android_version: #{min_android_version}  min_ios_version: #{min_ios_version}"
    )

    json(conn, %{min_android_version: min_android_version, min_ios_version: min_ios_version})
  end

  def delete(conn, %{"id" => token}) do
    current_user = Plug.current_resource(conn)
    Accounts.delete_device(token, current_user)

    json(conn, %{success: true})
  end

  def test_notify(conn, %{"type" => type, "timeout" => timeout}) do
    current_user = Plug.current_resource(conn)

    spawn(fn ->
      :timer.sleep(:timer.seconds(timeout))
      notify(conn, current_user, type)
    end)

    json(conn, %{success: true})
  end

  defp notify(_conn, current_user, type) do
    if !Enum.member?(
         [
           Const.action_commented(),
           Const.action_contest_commented(),
           Const.action_user_commented()
         ],
         type
       ) do
      activity =
        Repo.one(
          from(a in Activity,
            where: a.type == ^type,
            select: [:id],
            order_by: fragment("RANDOM()"),
            limit: 1
          )
        )

      if is_nil(activity) do
        Logger.warn("Nessuna attivita trovata di tipo #{type}")
      else
        NotifyJob.enqueue(:activity, activity.id, [current_user.id])
      end
    else
      flags = [
        photo: type == Const.action_commented(),
        contest: type == Const.action_contest_commented(),
        user: type == Const.action_user_commented()
      ]

      query =
        from(c in Comment,
          inner_join: t in Topic,
          on: [id: c.topic_id],
          select: [:id],
          order_by: fragment("RANDOM()"),
          where:
            (^flags[:photo] and not is_nil(t.photo_id)) or
              (^flags[:contest] and is_nil(t.photo_id) and not is_nil(t.contest_id)) or
              (^flags[:user] and is_nil(t.photo_id) and is_nil(t.contest_id)),
          limit: 1
        )

      comment = Repo.one(query)

      if is_nil(comment) do
        Logger.warn("Nessuna commento trovato")
      else
        NotifyJob.enqueue(:comment, comment.id, [current_user.id])
      end
    end
  end
end

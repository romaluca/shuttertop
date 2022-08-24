defmodule Shuttertop.FCM.PusherHttp do
  @moduledoc false
  import Ecto.{Query, Changeset}, warn: false

  require Logger

  alias Shuttertop.Repo
  alias Shuttertop.Accounts
  alias Shuttertop.Activities.Activity
  alias Shuttertop.FCM.Processor
  alias Shuttertop.Events.Event
  alias Shuttertop.Posts.Comment

  @spec push(:activity | :comment | :event, Integer.t(), [Integer.t()] | nil) :: nil | :ok | [any]
  def push(:comment, id, user_ids) do
    comment =
      from(a in Comment,
        select: [
          :id,
          :body,
          :user_id,
          :topic_id,
          :inserted_at,
          user: [:id, :name, :upload, :slug],
          topic: [
            :id,
            :photo_id,
            :contest_id,
            :user_to_id,
            photo: [:id, :name, :upload],
            contest: [:id, :name, :upload, :slug]
          ]
        ],
        preload: [:user, topic: [:photo, :contest]],
        where: a.id == ^id
      )
      |> Repo.one()

    if is_nil(comment) do
      Logger.error("PusherHttp push Comment not found #{id}")
    else
      Logger.debug("PusherHttp push Comment found #{id}")

      comment
      |> Processor.notify(user_ids)
      |> push_reg()
    end
  end

  def push(:activity, id, user_ids) do
    activity =
      from(a in Activity,
        select: [
          :type,
          :photo_id,
          :contest_id,
          :user_id,
          :user_to_id,
          user: [:id, :name, :upload, :slug],
          user_to: [:id, :name, :upload, :slug],
          contest: [:id, :name, :upload, :slug, :user_id],
          photo: [:id, :name, :upload, :slug, :user_id]
        ],
        preload: [:user, :user_to, :contest, :photo],
        where: a.id == ^id
      )
      |> Repo.one()

    if is_nil(activity) do
      Logger.error("PusherHttp push Activity not found #{id}")
    else
      Logger.debug("PusherHttp push Activity found #{id}")

      activity
      |> Processor.notify(user_ids)
      |> push_reg()
    end
  end

  def push(:event, id, user_ids) do
    event =
      from(e in Event,
        select: [
          :type,
          :week,
          :year,
          :photo_id,
          :contest_id,
          contest: [:id, :name, :upload, :slug, :user_id],
          photo: [:id, :name, :upload, :slug, :user_id]
        ],
        preload: [:contest, :photo],
        where: e.id == ^id
      )
      |> Repo.one()

    if is_nil(event) do
      Logger.error("PusherHttp push Event not found #{id}")
    else
      Logger.debug("PusherHttp push Event found #{id}")

      event
      |> Processor.notify(user_ids)
      |> push_reg()
    end
  end

  defp push_reg(notifies) when is_list(notifies) do
    for notify <- notifies, do: push_reg(notify)
  end

  defp push_reg(notify, last_id \\ 0)

  defp push_reg({:ids, query, data, params_i18n} = notify, last_id) do
    limit_ids = 1000

    registration_ids =
      query
      |> limit(^limit_ids)
      |> select([d, u], %{id: d.id, token: d.token, platform: d.platform, language: u.language})
      |> where([d], d.id > ^last_id)
      |> order_by([d], asc: d.id)
      |> Repo.all()

    tot = length(registration_ids)
    Logger.info("Notify push #{data[:body]} ids: #{tot}!")

    if registration_ids != [] do
      for platform <- ["android", "ios", "web"] do
        for lang <- ["it", "en"] do
          send_notify(registration_ids, platform, lang, data, params_i18n)
        end
      end
    end

    if tot == limit_ids, do: push_reg(notify, List.last(registration_ids)[:id])
  end

  defp push_reg({:topic, topic_name, data, params_i18n}, _) do
    Logger.info("Notify push #{data[:body]} topic: #{topic_name}!")
    env = if(Application.get_env(:shuttertop, :environment) == :prod, do: "", else: "-test")

    for platform <- ["android", "ios", "web"] do
      for lang <- ["it", "en"] do
        send_notify(
          "/topics/#{topic_name}-#{lang}-#{platform}#{env}",
          platform,
          lang,
          data,
          params_i18n
        )
      end
    end
  end

  defp push_reg(nil, _), do: Logger.debug("No notify to push")

  defp send_notify(dest, platform, lang, data, params_i18n) do
    final_dest =
      case dest do
        topic when is_binary(topic) ->
          topic

        [] ->
          nil

        _ ->
          dest
          |> Enum.filter(fn x -> x.platform == platform and x.language == lang end)
          |> Enum.map(fn x -> x.token end)
      end

    if !is_nil(final_dest) && final_dest != [] do
      data =
        Gettext.with_locale(lang, fn ->
          data
          |> translate_param(:body, params_i18n)
          |> translate_param(:title, params_i18n)
        end)

      Logger.debug(
        "send notify #{platform}-#{lang}: #{inspect(data)} i18n_params!!:: #{inspect(params_i18n)}"
      )

      notification =
        if platform == "android", do: nil, else: %{body: data[:body], title: data[:title]}

      final_dest
      |> Fcmex.push(
        data: data,
        notification: notification,
        collapse_key: params_i18n[:collapse_key]
      )
      |> case do
        [ok: %{"results" => results, "failure" => x}] when x > 0 ->
          check_token_errors(final_dest, results, x)

        ret ->
          Logger.debug("Risposta #{platform} notify: #{inspect(ret)}")
      end
    end
  end

  defp translate_param(data, param, params_i18n) when param in [:body, :title] do
    if !is_nil(params_i18n[param]) do
      t = Gettext.dgettext(ShuttertopWeb.Gettext, "dynamic", data[param], params_i18n)
      Map.put(data, param, t)
    else
      data
    end
  end

  defp check_token_errors(topic, results, failures) when is_binary(topic) do
    Logger.debug(
      "check_token_errors topic_name: #{topic} failures #{inspect(failures)} result #{inspect(results)}"
    )

    nil
  end

  defp check_token_errors(ids, results, failures) do
    Logger.debug("check_token_errors: failures #{failures}")

    for i <- 0..Enum.count(results) do
      result = Enum.at(results, i)
      id = Enum.at(ids, i)

      case result do
        %{"error" => "InvalidRegistration"} ->
          Logger.info("invalid device token to delete: #{id}")
          Accounts.delete_device_by_token(id)

        %{"error" => "NotRegistered"} ->
          Logger.info("not registered device token to delete: #{id}")
          Accounts.delete_device_by_token(id)

        msg ->
          Logger.info("check_token_errors token mesage not found: #{inspect(msg)}")
      end
    end
  end
end

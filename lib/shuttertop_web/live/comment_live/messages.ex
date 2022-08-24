defmodule ShuttertopWeb.CommentLive.Messages do
  use ShuttertopWeb, :live_page

  require Logger

  alias Shuttertop.{Accounts, Posts}
  alias Shuttertop.Accounts.User
  alias ShuttertopWeb.Components.Chat

  @page_size 30

  def render(%{is_loading: true} = assigns) do
    ShuttertopWeb.CommonView.render("loading.html", assigns)
  end

  def render(assigns) do
    ShuttertopWeb.CommentView.render("messages.html", assigns)
  end

  def mount(params, _session, socket) do
    case socket.assigns.current_user do
      %User{} ->
        {:ok,
         assign(socket,
           body_id: "commentsPage",
           page: 1,
           page_title: gettext("contest fotografici improvvisati e via discorrendo"),
           title_bar: gettext("Messaggi"),
           app_version: Application.spec(:shuttertop, :vsn)
         )
         |> fetch_mount(params)}

      _ ->
        {:ok, push_redirect(socket, to: Routes.live_path(socket, ShuttertopWeb.AuthLive.Index))}
    end
  end

  defp fetch_mount(socket, params) do
    if connected?(socket) do
      current_user = socket.assigns.current_user

      {topic, topic_id} =
        case params["new_message"] do
          nil ->
            {nil, params["id"]}

          user_to_id ->
            user_to = Accounts.get_user_by(id: user_to_id)

            Posts.get_topic(current_user.id, user_to.id)
            |> case do
              nil ->
                {:ok, %{topic: %{id: new_topic_id}}} =
                  Posts.create_topic(
                    %{user_to_id: user_to.id, user_id: current_user.id},
                    user_to.id
                  )

                {Posts.get_topic(new_topic_id), new_topic_id}

              t ->
                {t, t.id}
            end
        end

      Chat.subscribe_topic(topic, socket)
      Accounts.reset_notify_message_count(current_user)
      topics = Posts.list_topics(%{}, current_user)

      assign(socket, %{
        limit: @page_size,
        topics: topics,
        no_messages: topics.total_entries == 0,
        topic_id: topic_id,
        topic: topic
      })
      |> fetch(params)
    else
      assign(socket, is_loading: true)
    end
  end

  defp fetch(socket, _), do: socket

  def handle_params(%{"id" => id}, _, %{assigns: %{topics: topics}} = socket) do
    topic = Enum.find(topics, fn x -> to_string(x.id) == id end)
    Chat.subscribe_topic(topic, socket)
    {:noreply, assign(socket, topic: topic)}
  end

  def handle_params(_, _, socket), do: {:noreply, socket}

  def handle_event("comment-focus", _, socket), do: {:noreply, socket}

  def handle_event("comment-blur", _, socket), do: {:noreply, socket}

  def handle_event("more", _, %{assigns: %{page: page, current_user: current_user}} = socket) do
    page = page + 1
    topics = Posts.list_topics(%{page: page}, current_user)
    {:noreply, assign(socket, topics: topics, page: page)}
  end

  def handle_event("show_topic", %{"small_screen" => small_screen}, socket) do
    topics = socket.assigns.topics

    topic =
      cond do
        topics == nil || topics.entries == [] ->
          nil

        is_nil(socket.assigns.topic_id) ->
          if small_screen, do: nil, else: List.first(topics.entries)

        true ->
          Enum.find(topics, fn x -> to_string(x.id) == socket.assigns.topic_id end)
      end

    Chat.subscribe_topic(topic, socket)
    {:noreply, assign(socket, small_screen: small_screen, topic: topic)}
  end

  def handle_info({_, :created, comment}, socket) do
    element_id = Posts.get_topic_element_id(socket.assigns.topic, socket.assigns.current_user)
    send_update(Chat, id: "elementComment-#{element_id}", new_comment: comment)
    {:noreply, socket}
  end
end

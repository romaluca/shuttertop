defmodule ShuttertopWeb.Components.Chat do
  use ShuttertopWeb, :live_component

  alias Shuttertop.{Posts}
  alias Shuttertop.Posts.{Comment, Topic}
  alias ShuttertopWeb.Components.Modal

  require Logger
  alias Phoenix.LiveView.JS

  def update(%{new_comment: new_comment}, socket) do
    {:ok,
     assign(socket,
       new_comments: socket.assigns.new_comments ++ [new_comment],
       count: socket.assigns.count + 1
     )}
  end

  def update(assigns, socket) do
    %{
      page_id: page_id,
      entity: entity,
      topic: topic,
      current_user: current_user
    } = assigns

    {:ok,
     assign(socket, %{
       entity: entity,
       topic: topic,
       min_date: Timex.now(),
       page_id: page_id,
       comment_changeset: Comment.changeset(%Comment{}),
       current_user: current_user,
       page: 1,
       comments: [],
       new_comments: []
     })
     |> fetch()}
  end

  def render(assigns) do
    ~H"""
      <div id={"commentsContainer"} data-totals={ @count } phx-hook="CommentUpdate">
      <ul class="list-unstyled comments" >
        <form phx-submit="load-more" id="commentsMoreButton" phx-target={@myself}>
            <button phx-disable-with="loading..." class="more"><%= gettext "Visualizza commenti precendenti..." %></button>
        </form>
        <%= if @new_comments == [] && @comments == [] do %>
          <div class="empty-chat desc-empty-container">
              <i class="icons message" /><br />
              <%= translate "Nessun messaggio ancora" %>
          </div>
        <% end %>
        <div phx-update="prepend" id={"comments-#{@entity.id}"} phx-target={@myself}>
        <%= for comment <- @comments do %>
            <.comment comment={comment} socket={@socket} />
        <% end %>
        </div>
        <div phx-update="append" id={"new_comments-#{@entity.id}"} class={"new-comments#{if @new_comments == [], do: " d-none"}"} phx-target={@myself}>
        <%= for comment <- @new_comments do %>
          <.comment comment={comment} socket={@socket} />
        <% end %>
        </div>
      </ul>
      <div class="comment-new">
          <div class="container">
            <.form let={f} for={@comment_changeset}  phx-submit="save" id="comment-form" phx-target={@myself}>
                <div class="input-group">
                    <%= textarea f, :body, rows: 1, placeholder: "Commenta", class: "form-control",
                            phx_blur: JS.push("comment-blur", target: "##{@page_id}"),
                            phx_focus: JS.push("comment-focus", target: "##{@page_id}") %>
                    <span class="input-group-btn">
                        <%= submit class: "btn btn-primary-putline" do %>
                            <i class="icons send"></i>
                        <% end %>
                    </span>
                </div>
            </.form>
          </div>
      </div>
      </div>
    """
  end

  def comment(assigns) do
    ~H"""
    <li class="comment-container media" id={"comment-#{ @comment.id }"}>
        <div class="me-3 d-flex">
            <%= img_tag upload_url(@comment.user, :thumb_small), loading: "lazy", class: "user-img" %>
        </div>
        <div class="media-body">
            <div class="header">
                <%= live_redirect @comment.user.name, to: Routes.live_path(@socket, ShuttertopWeb.UserLive.Show, slug_path(@comment.user)), class: "user" %> &middot;
                <span class="created_at" data-at={ Timex.Timezone.convert(@comment.inserted_at, "Etc/UTC") }><%= Timex.from_now(@comment.inserted_at, locale()) %></span>
            </div>
            <div class="message"><%= @comment.body %></div>

        </div>
    </li>
    """
  end

  def handle_event("save", %{"comment" => %{"body" => body}}, socket) do
    if is_nil(socket.assigns.current_user) do
      send_update(Modal, id: "modalDialog", type: "login")
      {:noreply, socket}
    else
      Posts.create_comment(socket.assigns.entity, body, socket.assigns.current_user)
      |> case do
        {:ok, %{comment: _comment}} ->
          {:noreply, assign(socket, comment_changeset: Comment.changeset(%Comment{}))}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, comment_changeset: changeset)}
      end
    end
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, socket |> assign(page: assigns.page + 1) |> fetch()}
  end

  def handle_event("comment-focus", _, socket), do: {:noreply, socket}

  def handle_event("comment-blur", _, socket), do: {:noreply, socket}

  defp fetch(
         %{
           assigns: %{
             page: page,
             current_user: current_user,
             min_date: min_date,
             topic: %Topic{} = topic
           }
         } = socket
       ) do
    comments = Posts.most_recent_comments(topic, %{page: page, min_date: min_date}, current_user)
    assign(socket, comments: Enum.reverse(comments.entries), count: comments.total_entries)
  end

  defp fetch(socket), do: assign(socket, comments: [], count: 0)

  def subscribe_topic(%Topic{id: id} = topic, %{
        assigns: %{current_user: current_user, topic: %Topic{id: old_id} = old_topic}
      }) do
    if id != old_id do
      Posts.unsubscribe_topic(old_topic, current_user)
      Posts.subscribe_topic(topic, current_user)
    end
  end

  def subscribe_topic(%Topic{} = topic, %{assigns: %{current_user: current_user}}) do
    Posts.subscribe_topic(topic, current_user)
  end

  def subscribe_topic(_, _), do: nil
end

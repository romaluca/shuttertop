defmodule ShuttertopWeb.AdminLive.RandomVoteForm do
  use ShuttertopWeb, :live_component

  alias Shuttertop.Votes

  require Logger

  def render(assigns) do
    ~H"""
    <div>
    <%= if @closed do %>
        <button class="btn btn-primary" phx-target={@myself} phx-click="open">Nuovi voti</button>
    <% else %>
    <%= form_tag "#", [phx_submit: :save, phx_target: @myself, class: "form-random-vote", id: "form-random-vote", phx_hook: "RandomVoteForm"] do %>
        <div class="input-group">
            <%= text_input :random, :contest_id, placeholder: gettext("Contest id"), class: "form-control" %>
            <%= text_input :random, :photo_id, placeholder: gettext("Photo id"), class: "form-control" %>
            <%= text_input :random, :max_vote, placeholder: gettext("Max votes"), class: "form-control" %>
            <span class="input-group-btn">
                <%= submit Gettext.gettext(ShuttertopWeb.Gettext, "save"), phx_disable_with: Gettext.gettext(ShuttertopWeb.Gettext, "Saving..."), class: "btn btn-secondary" %>
            </span>
        </div>
    <% end %>
    <% end %>
    </div>
    """
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{user_id: user_id}, socket) do
    socket =
      socket
      |> assign(%{
        user_id: user_id,
        closed: true
      })

    {:ok, socket}
  end

  def handle_event("open", _args, socket) do
    {:noreply, assign(socket, closed: false)}
  end

  def handle_event("save", %{"random" => random_params} = _args, socket) do
    {:ok} = Votes.vote_random(random_params)

    {:noreply,
     socket
     |> assign(closed: true)
     |> put_flash(:info, "Contest/Photo successfully.")}
  end
end

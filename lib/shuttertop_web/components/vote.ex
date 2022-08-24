defmodule ShuttertopWeb.Components.Vote do
  use ShuttertopWeb, :live_component

  alias Shuttertop.Votes
  alias ShuttertopWeb.Components.Modal

  require Logger

  def render(assigns) do
    msg = live_flash(assigns[:flash], :error)

    ~H"""
    <button phx-click="vote" phx-target={@myself} data-votes={@photo.votes_count} data-position={@photo.position} class={if @active, do: "actived" } phx-hook="VoteBtn" id={"vote-#{@photo.id}"}
          error-msg={if !is_nil(msg), do: Gettext.gettext(ShuttertopWeb.Gettext, msg), else: ""}>
          <%= if is_nil(assigns[:label_mode]) do %>
          <span class="votes"><%= @photo.votes_count %></span>
          <% end %>
          <i class={"top-icon icons heart#{if @active, do: "_fill"}"}></i>
          <%= if !is_nil(assigns[:label_mode]) do %>
          <span class="label"><%= gettext("top") %></span>
          <% end %>
    </button>
    """
  end

  def update(
        %{
          photo: photo,
          current_user: current_user
        } = assigns,
        socket
      ) do
    {:ok,
     socket
     |> assign(%{
       active: Votes.is_voted(photo, current_user),
       photo: photo,
       label_mode: assigns[:label_mode],
       current_user: current_user
     })}
  end

  def handle_event("vote", _, socket) do
    if is_nil(socket.assigns.current_user) do
      send_update(Modal, id: "modalDialog", type: "login")
      {:noreply, socket}
    else
      current_user = socket.assigns.current_user
      is_add = !socket.assigns.active

      vote_ret =
        if is_add do
          Votes.add(socket.assigns.photo, current_user)
        else
          Votes.remove(socket.assigns.photo, current_user)
        end

      case vote_ret do
        {:ok, photo} ->
          active = Votes.is_voted(photo, current_user)
          params = assign(socket, active: active, photo: photo)
          {:noreply, params}

        {:error, %{status: 2}} ->
          Logger.warn("Expired contest")
          {:noreply, put_flash(socket, :error, gettext("Contest terminato"))}

        ret ->
          Logger.error("Cannot vote: #{inspect(ret)}")
          {:noreply, socket}
      end
    end
  end
end

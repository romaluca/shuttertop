defmodule ShuttertopWeb.Components.Follow do
  use ShuttertopWeb, :live_component

  alias Shuttertop.Follows
  alias ShuttertopWeb.Components.Modal

  require Logger

  def render(assigns) do
    ~H"""
    <button phx-click={"follow"} phx-target={@myself} class={"#{assigns[:class]} #{if @active, do: " actived"}"} id={"#{get_entity_name(@entity)}-follow-#{@entity.id}"}>
        <i class={"icons follow#{unless @active, do: "-outline"}"}></i>
        <span><%= if(@active, do: gettext("seguendo"), else: gettext("segui")) %></span>
    </button>
    """
  end

  def update(%{entity: entity, current_user: current_user} = params, socket) do
    {:ok,
     socket
     |> assign(%{
       entity: entity,
       class: params[:class],
       active: Follows.is_following(entity),
       current_user: current_user
     })}
  end

  def handle_event(_, _, %{assigns: %{current_user: current_user}} = socket)
      when is_nil(current_user) do
    send_update(Modal, id: "modalDialog", type: "login")
    {:noreply, socket}
  end

  def handle_event(
        "follow",
        _,
        %{assigns: %{entity: entity, current_user: current_user, active: active}} = socket
      ) do
    {:ok, element} =
      if active do
        Follows.remove(entity, current_user)
      else
        Follows.add(entity, current_user)
      end

    {:noreply,
     assign(socket, %{
       entity: element,
       active: Follows.is_following(element)
     })}
  end
end

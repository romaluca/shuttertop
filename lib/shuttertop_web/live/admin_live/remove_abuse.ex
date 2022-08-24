defmodule ShuttertopWeb.AdminLive.RemoveAbuseForm do
  use ShuttertopWeb, :live_component

  alias Shuttertop.{Contests, Photos}

  require Logger

  def render(assigns) do
    ~H"""
    <div class="ms-3">
    <%= if @closed do %>
        <button class="btn btn-primary" phx-target={@myself} phx-click="open">Rimuovi abuso</button>
    <% else %>
    <%= form_tag "#", [phx_submit: :remove, phx_target: @myself, class: "form-abuse", id: "form-abuse", phx_hook: "FormAbuse"] do %>
        <div class="input-group">
            <%= text_input :abuse, :contest_id, placeholder: gettext("Contest id"), class: "form-control" %>
            <%= text_input :abuse, :photo_id, placeholder: gettext("Photo id"), class: "form-control" %>
            <span class="input-group-btn">
                <%= submit Gettext.gettext(ShuttertopWeb.Gettext, "Remove"), phx_disable_with: Gettext.gettext(ShuttertopWeb.Gettext, "Removing..."), class: "btn btn-secondary" %>
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

  def handle_event("remove", %{"abuse" => %{"contest_id" => id}} = _args, socket) when id != "" do
    Logger.warn("abuse contest_id: #{id}")
    _ret = Contests.remove_abuse(id)
    {:noreply,
     socket
     |> assign(closed: true)
     |> put_flash(:info, "Contest/Photo removed successfully.")}
  end

  def handle_event("remove", %{"abuse" => %{"photo_id" => id}} = _args, socket) when id != "" do
    Logger.warn("abuse photo_id: #{id}")
    _ret = Photos.remove_abuse(id)
    {:noreply,
     socket
     |> assign(closed: true)
     |> put_flash(:info, "Contest/Photo removed successfully.")}
  end
end

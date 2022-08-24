defmodule ShuttertopWeb.Components.Modal do
  use ShuttertopWeb, :live_component

  require Logger

  def update(params, socket) do
    {:ok, socket |> assign(params)}
  end

  def render(%{type: type} = assigns) when type != nil do
    ~H"""
    <div>
      <div class={"modal #{type} fade show"} style={"display:block;"} id="modalDialog" tabindex="-1" role="dialog" aria-labelledby="modalLabel" aria-hidden="true">
        <div class="modal-dialog" role="document">
          <div class="modal-content">
            <div class={"modal-body"}>
              <%= case type do
                    "login" ->
                      live_component(ShuttertopWeb.AuthLive.Login, Map.put(assigns, :id, "liveLogin"))
                    "search" ->
                      live_component(ShuttertopWeb.Components.Search, Map.put(assigns, :id, "searchModalContainer"))
                    "profile_menu" ->
                      live_component(ShuttertopWeb.Components.ProfileMenu, assigns)
                    "share" ->
                      live_component(ShuttertopWeb.Components.Share, assigns)

                    _ ->
                      ""
                  end %>
            </div>
          </div>
        </div>
      </div>
      <div class="modal-backdrop fade show" phx-click="hide-modal" phx-target={@myself} id="backDropModal"></div>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div />
    """
  end

  def handle_event("show-modal", %{"type" => "share", "url" => url}, socket) do
    {:noreply, assign(socket, type: "share", url: url)}
  end

  def handle_event("show-modal", %{"type" => type}, socket) do
    {:noreply, assign(socket, type: type)}
  end

  def handle_event("hide-modal", _, socket) do
    {:noreply, assign(socket, type: nil)}
  end
end

defmodule ShuttertopWeb.Components.ProfileMenu do
  use ShuttertopWeb, :live_component
  require Logger

  def render(assigns) do
    ~H"""
    <div class="profile text-center">
      <a href="#" phx-click="hide-modal" phx-target="#modalDialog" id="profileMenuHideModal"><i class="icons close" aria-hidden="true"></i></a>
      <%= if is_nil(assigns[:current_user]) do %>
        <a href="?locale=it"><%= gettext "italiano" %></a>
              <a href="?locale=en"><%= gettext "inglese" %></a>
      <% else %>
        <%= img_tag upload_url(@current_user,:thumb_small), class: "user-img mb-5" %>
        <%= live_redirect gettext("Visualizza il profilo"), to: Routes.live_path(@socket, ShuttertopWeb.UserLive.Show, slug_path(@current_user)) %>
        <%= live_redirect gettext("Impostazioni"), to: Routes.live_path(@socket, ShuttertopWeb.UserLive.Edit) %>
        <%= if is_admin(@current_user) do  %>
          <%= live_redirect gettext("Dashboard"), to: "/dashboard" %>
          <%= live_redirect gettext("Admin"), to: Routes.live_path(@socket, ShuttertopWeb.AdminLive.Show) %>
        <% end %>
        <%= link gettext("Logout"), method: :delete, to: Routes.auth_path(@socket, :logout), class: "btn btn-outline-primary logout_btn mt-5" %>
      <% end %>
    </div>
    """
  end

  def update(%{current_user: current_user} = _params, socket) do
    {:ok, socket |> assign(current_user: current_user)}
  end
end

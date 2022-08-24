defmodule ShuttertopWeb.Components.Search do
  use ShuttertopWeb, :live_component
  require Logger
  alias Shuttertop.{Accounts, Contests}

  def render(assigns) do
    ~H"""
    <div class="search-container section search-modal modal-section" id="searchContainer">
      <form phx-change="search" id="searchForm" phx-target="#searchContainer">
        <span class="input-group">
          <span class="input-group-addon">
            <a href="#" class="d-lg-none" phx-click="hide-modal" id="searchHideModal"><i class="icons prev" aria-hidden="true"></i></a>
            <i class="icons search d-none d-lg-inline-block" aria-hidden="true"></i>
          </span>
          <%= text_input :search_field, :query, placeholder: gettext("Cerca un contest o una persona") <> "...",
                class: "form-control", autocomplete: "off", phx_debounce: "300",
                id: "searchInput", value: if(!is_nil(assigns[:params]) && !is_nil(assigns[:params]["search"]), do: assigns[:params]["search"]) %>
          <span class="input-group-addon d-lg-none">
            <i class="icons search" aria-hidden="true"></i>
          </span>
        </span>
      </form>
      <div id="searchResults" class="container">
        <%= if assigns[:search] do %>
        <div class="pt-5">
            <h4><%= gettext "Contest" %></h4>
            <div class="list-group">
                <%= for i <- @contests do %>
                    <%= render ShuttertopWeb.ContestView, "contest_ori.html", contest: i, conn: @socket, current_user: @current_user %>
                <% end %>
                <%= cond do
                        @contests.total_entries > 5 ->
                        live_redirect(gettext("Visualizza tutti i contest per") <> " \"#{@search}\"...", to: Routes.live_path(@socket, ShuttertopWeb.ContestLive.Index, search: @search), class: "others-link")
                        @contests.total_entries == 0 ->
                            content_tag(:div, "Nessun contest trovato", class: "empty")
                        true ->
                            ""
                    end %>
            </div>
        </div>
        <div class="pt-4">
            <h4><%= gettext "Utenti" %></h4>
            <div class="list-group">
                <%= for i <- @users do %>
                    <li class="list-group-item">
                    <%= live_redirect to: Routes.live_path(@socket, ShuttertopWeb.UserLive.Show, slug_path(i)), class: "user" do %>
                        <div class="d-flex">
                            <%= img_tag upload_url(i, :thumb), loading: "lazy", class: "user-img me-3" %>
                            <div class="info">
                                <h5 class="name"><%= i.name %></h5>
                                <div class="stats">
                                    <%= i.score %> <%= gettext "punti"%> &middot;
                                    <%= i.winner_count %> <%= gettext "vittorie"%> &middot;
                                    <%= i.photos_count %> <%= gettext "foto"%>
                                </div>
                            </div>
                        </div>
                    <% end %>
                    </li>
                <% end %>
                <%= cond do
                        @users.total_entries > 5 ->
                            live_redirect gettext("Visualizza tutti gli utenti per") <> " \"#{@search}\"...", to: Routes.live_path(@socket, ShuttertopWeb.UserLive.Index, search: @search), class: "others-link"
                        @users.total_entries == 0 ->
                            content_tag(:div, "Nessun contest trovato", class: "empty")
                        true ->
                            ""
                    end %>
            </div>
        </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("search", %{"search_field" => %{"query" => s}} = params, socket) do
    if String.length(s) < 2 do
      {:noreply, socket}
    else
      with {:ok, user_params} <- users_params(%{search: s, page_size: 5}, params),
           {:ok, contest_parms} <- contests_params(%{search: s, page_size: 5}, params),
           users <- Accounts.get_users(user_params),
           contests = Contests.get_contests(contest_parms) do
        {:noreply,
         assign(socket,
           contests: contests,
           users: users,
           search: s
         )}
      end
    end
  end

  def handle_event(params, _socket) do
    Logger.warn(inspect(params))
  end
end

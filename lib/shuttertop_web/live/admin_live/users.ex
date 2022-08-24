defmodule ShuttertopWeb.AdminLive.Users do
  use ShuttertopWeb, :live_component

  require Logger

  alias Shuttertop.Accounts

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ShuttertopWeb.AdminView.render("users.html", assigns)
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{user_id: user_id}, socket) do
    authorizations = Accounts.get_authorizations(%{page_size: 10})

    socket =
      socket
      |> assign(%{
        page: 1,
        authorizations: authorizations,
        selected: nil,
        user_id: user_id
      })

    {:ok, socket}
  end

  def handle_event(
        "next_page",
        _,
        %{assigns: %{page: page, authorizations: authorizations}} = socket
      ) do
    if authorizations != [] do
      new_page = page + 1
      new_authorizations = Accounts.get_authorizations(%{page: new_page, page_size: 10})

      if new_authorizations.entries != [] do
        {:noreply, assign(socket, %{authorizations: new_authorizations, page: new_page})}
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("select", %{"id" => id}, socket) do
    if is_nil(id) do
      {:no_reply, socket}
    else
      {value, _} = Integer.parse(id)
      {:noreply, assign(socket, %{selected: value})}
    end
  end

  def handle_event(
        "set_type",
        %{"user" => %{"type" => type}},
        %{assigns: %{selected: selected}} = socket
      ) do
    current_user = Accounts.get_user(socket.assigns.user_id)

    if is_nil(selected) do
      {:noreply, socket}
    else
      selected
      |> Accounts.get_user!()
      |> Accounts.update_user(%{type: type}, current_user)

      {:noreply,
       push_redirect(socket,
         to: Routes.live_path(socket, ShuttertopWeb.AdminLive.Show),
         replace: true
       )}
    end
  end

  def handle_event("reset_upload", _, %{assigns: %{selected: selected}} = socket) do
    if is_nil(selected) do
      {:noreply, socket}
    else
      selected
      |> Accounts.get_user!()
      |> Accounts.update_upload(nil)

      {:noreply,
       push_redirect(socket,
         to: Routes.live_path(socket, ShuttertopWeb.AdminLive.Show),
         replace: true
       )}
    end
  end

  def handle_event("prev_page", _, %{assigns: %{page: page}} = socket) do
    if page > 1 do
      page = page - 1
      authorizations = Accounts.get_authorizations(%{page: page, page_size: 10})
      {:noreply, assign(socket, %{authorizations: authorizations, page: page})}
    else
      {:noreply, socket}
    end
  end
end

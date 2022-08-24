defmodule ShuttertopWeb.AdminLive.Activities do
  use ShuttertopWeb, :live_component

  alias Shuttertop.{Accounts, Activities}

  require Logger

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ShuttertopWeb.AdminView.render("activities.html", assigns)
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{user_id: user_id}, socket) do
    current_user = Accounts.get_user(user_id)
    activities = Activities.get_latest_all_activities(%{page_size: 10}, current_user)

    socket =
      socket
      |> assign(%{
        page: 1,
        user_id: user_id,
        selected: nil,
        activities: activities
      })

    {:ok, socket}
  end

  def handle_event("select", %{"id" => id}, socket) do
    if is_nil(id) do
      {:no_reply, socket}
    else
      {value, _} = Integer.parse(id)
      {:noreply, assign(socket, %{selected: value})}
    end
  end

  def handle_event("send_notify", _, %{assigns: %{selected: selected}} = socket) do
    if is_nil(selected) do
      {:noreply, socket}
    else
      Activities.send_notify({:ok, %{activity: %{id: selected, type: nil}}})

      {:noreply,
       push_redirect(socket,
         to: Routes.live_path(socket, ShuttertopWeb.AdminLive.Show),
         replace: true
       )}
    end
  end

  def handle_event("next_page", _, %{assigns: %{page: page, activities: activities}} = socket) do
    if activities != [] do
      new_page = page + 1
      current_user = Accounts.get_user(socket.assigns.user_id)

      new_activities =
        Activities.get_latest_all_activities(%{page: new_page, page_size: 10}, current_user)

      if new_activities.entries != [] do
        {:noreply, assign(socket, %{activities: new_activities, page: new_page})}
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("prev_page", _, %{assigns: %{page: page}} = socket) do
    if page > 1 do
      page = page - 1
      current_user = Accounts.get_user(socket.assigns.user_id)

      activities =
        Activities.get_latest_all_activities(%{page: page, page_size: 10}, current_user)

      {:noreply, assign(socket, %{activities: activities, page: page})}
    else
      {:noreply, socket}
    end
  end
end

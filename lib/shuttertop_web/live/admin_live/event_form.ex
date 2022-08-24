defmodule ShuttertopWeb.AdminLive.EventForm do
  use ShuttertopWeb, :live_component

  require Logger
  require Shuttertop.Constants

  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Jobs.NotifyJob
  alias Shuttertop.Events
  alias Shuttertop.Events.Event
  alias ShuttertopWeb.AdminView

  def render(assigns) do
    AdminView.render("event_form.html", assigns)
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(%{user_id: user_id}, socket) do
    {:ok, week, year} = Event.get_week_year()

    changeset =
      Event.changeset(%Event{week: week, year: year, type: Const.event_type_top_of_week()})

    events = Events.get_events()

    socket =
      socket
      |> assign(%{
        changeset: changeset,
        user_id: user_id,
        closed: true,
        events: events
      })

    {:ok, socket}
  end

  def handle_event("open", _args, socket) do
    {:noreply, assign(socket, closed: false)}
  end

  def handle_event("delete", %{"id" => id} = _args, socket) do
    Events.delete_event(id)
    events = Events.get_events()
    {:noreply, assign(socket, events: events)}
  end

  def handle_event("save", %{"event" => event_params} = _args, socket) do
    case Events.create_event(event_params) do
      {:ok, event} ->
        NotifyJob.enqueue(:event, event.id)

        {:noreply,
         socket
         |> assign(closed: true)
         |> put_flash(:info, "Event created successfully.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end

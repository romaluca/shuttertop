defmodule ShuttertopWeb.AdminLive.Mailer do
  use ShuttertopWeb, :live_component

  require Logger
  require Shuttertop.Constants

  alias ShuttertopWeb.AdminView
  alias ShuttertopWeb.UserMailer

  def render(assigns) do
    AdminView.render("mailer.html", assigns)
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(_, socket) do
    socket =
      socket
      |> assign(%{
        closed: true
      })

    {:ok, socket}
  end

  def handle_event("open", _args, socket) do
    {:noreply, assign(socket, closed: false)}
  end

  def handle_event(
        "send_mail",
        %{"email" => %{"message" => message, "subject" => subject, "email" => email}},
        socket
      ) do
    ret =
      UserMailer.send_mail(email, subject, message)
      |> Shuttertop.Mailer.deliver!()

    {:noreply, assign(socket, %{mail_result: inspect(ret)})}
  end
end

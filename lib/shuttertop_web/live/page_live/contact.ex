defmodule ShuttertopWeb.PageLive.Contact do
  use ShuttertopWeb, :live_page

  require Logger

  alias Shuttertop.Jobs.UserMailerJob

  def render(assigns) do
    ShuttertopWeb.PageView.render("contact.html", assigns)
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(%{
       body_id: "contactPage",
       recaptcha: true,
       app_version: Application.spec(:shuttertop, :vsn)
     })}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "save",
        %{
          "contact" => %{"name" => name, "email" => email, "description" => description},
          "g-recaptcha-response" => recaptcha
        },
        socket
      ) do
    if name != "" && email != "" && description != "" do
      {:ok, result} =
        HTTPoison.post(
          "https://www.google.com/recaptcha/api/siteverify",
          {:form, [secret: "6LctTSwUAAAAANEnw9MQSvHVfIt3aIcnhPeFTYib", response: recaptcha]},
          %{"Content-type" => "application/form-data"}
        )

      result =
        result.body
        |> Poison.decode!()

      socket =
        case result do
          %{"success" => true} ->
            UserMailerJob.enqueue_contact_us(name, email, description)

            socket
            |> put_flash(:info, "Messaggio inviato!")
            |> push_redirect(to: Routes.live_path(socket, ShuttertopWeb.ActivityLive.Index))

          _ ->
            socket
            |> put_flash(:info, "You are a robot!")
            |> push_redirect(to: Routes.live_path(socket, ShuttertopWeb.ActivityLive.Index))
        end

      {:noreply, socket}
    else
      {:noreply, socket}
      # render(socket, "contact.html", current_user: current_user, recaptcha: true)
    end
  end

  def handle_event("save", _, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "You are a robot!")
     |> push_redirect(to: Routes.live_path(socket, ShuttertopWeb.ActivityLive.Index))}
  end
end

defmodule ShuttertopWeb.PageController do
  use ShuttertopWeb, :controller

  require Logger

  alias Shuttertop.Guardian.Plug, as: GuardianPlug
  alias Shuttertop.Jobs.UserMailerJob

  action_fallback(ShuttertopWeb.FallbackController)

  def contact(conn, %{
        "contact" => %{"name" => name, "email" => email, "description" => description},
        "g-recaptcha-response" => recaptcha
      }) do
    current_user = GuardianPlug.current_resource(conn)

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

      case result do
        %{"success" => true} ->
          UserMailerJob.enqueue_contact_us(name, email, description)

          conn
          |> put_flash(:info, "Messaggio inviato!")
          |> redirect(to: "/")

        _ ->
          conn
          |> put_flash(:info, "You are a robot!")
          |> redirect(to: "/")
      end
    else
      render(conn, "contact.html", current_user: current_user, recaptcha: true)
    end
  end

  def contact(conn, _params) do
    current_user = GuardianPlug.current_resource(conn)
    render(conn, "contact.html", current_user: current_user, recaptcha: true)
  end
end

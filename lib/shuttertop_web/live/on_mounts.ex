defmodule ShuttertopWeb.InitLiveAssigns do
  import Phoenix.LiveView
  require Logger
  def on_mount(:default, _params, %{"locale" => locale} = session, socket) do
    Gettext.put_locale(ShuttertopWeb.Gettext, locale)

    socket =
      assign_new(socket, :current_user, fn ->
        find_current_user(session)
      end)

    {:cont, socket}
  end

  defp find_current_user(%{"guardian_default_token" => token}) when token != nil do
    case Shuttertop.Guardian.resource_from_token(token) do
      {:ok, user, _} ->
        user
      _ ->
        nil
    end
  end

  defp find_current_user(_), do: nil
end

defmodule ShuttertopWeb.RequiredLiveAuth do
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    if socket.assigns.current_user && socket.assigns.current_user.is_confirmed do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/auth/identity")}
    end
  end
end

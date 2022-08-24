defmodule ShuttertopWeb.UserSocket do
  use Phoenix.Socket

  channel("contest:*", ShuttertopWeb.ContestChannel)
  channel("photo:*", ShuttertopWeb.PhotoChannel)
  channel("user:*", ShuttertopWeb.UserChannel)

  require Logger

  @impl true
  def connect(%{"token" => jwt}, socket) do
    case Guardian.Phoenix.Socket.authenticate(socket, Shuttertop.Guardian, jwt) do
      {:ok, authed_socket} ->
        {:ok, authed_socket}

      _ ->
        # unauthenticated socket
        {:ok, socket}
    end
  end

  @impl true
  def connect(_params, socket) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end

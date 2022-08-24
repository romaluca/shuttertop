defmodule ShuttertopWeb.LayoutView do
  use ShuttertopWeb, :view

  require Logger

  def get_active_section(%Plug.Conn{} = conn) do
    case conn.request_path do
      "/" ->
        :home

      "/contests" <> _d ->
        :contests

      "/leaders" ->
        :users

      "/notifies" ->
        :notifies

      _ ->
        :other
    end
  end

  def get_active_section(socket) when socket != nil do
    case socket.view do
      ShuttertopWeb.CommentLive.Messages ->
        :messages

      ShuttertopWeb.ActivityLive.Index ->
        :home

      ShuttertopWeb.ContestLive.Index ->
        :contests

      ShuttertopWeb.ContestLive.Show ->
        :contests

      ShuttertopWeb.ActivityLive.Notifies ->
        :notifies

      ShuttertopWeb.UserLive.Show ->
        :users

      ShuttertopWeb.UserLive.Index ->
        :users

      _ ->
        :other
    end
  end

  def get_active_section() do
    :other
  end
end

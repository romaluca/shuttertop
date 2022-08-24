defmodule ShuttertopWeb.LiveView.HelpersPage do
  import Phoenix.LiveView

  defmacro __using__(_) do
    quote do
      on_mount ShuttertopWeb.InitLiveAssigns
      require Logger

      def handle_event("show-modal", %{"type" => "share", "url" => url}, socket) do
        send_update(ShuttertopWeb.Components.Modal, %{type: "share", url: url, id: "modalDialog"})
        {:noreply, socket}
      end

      def handle_event("show-modal", %{"type" => type}, socket) do
        send_update(ShuttertopWeb.Components.Modal, %{type: type, id: "modalDialog"})
        {:noreply, socket}
      end
    end
  end
end

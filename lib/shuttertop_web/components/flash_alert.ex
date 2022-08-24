defmodule ShuttertopWeb.Components.FlashAlert do
  use ShuttertopWeb, :live_component

  def render(%{flash: flash, type: type} = assigns) do
    assigns
    |> assign(:flash_msg, live_flash(flash, type))
    |> render_alert()
  end

  defp render_alert(%{flash_msg: nil} = assigns), do: ~H""

  defp render_alert(%{flash_msg: msg, type: type} = assigns) do
    assigns =
      assigns
      |> assign(:type_string, Atom.to_string(type))

    ~H"""
    <div class={"alert alert-#{@type_string} alert-dismissible fade show autoclose"} role='alert'
      phx-click="lv:clear-flash" phx-value-key="info">
      <button type='button' class='btn-close' aria-label='Close'></button>
      <%= msg %>
    </div>
    """
  end
end

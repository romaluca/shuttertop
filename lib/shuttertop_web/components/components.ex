defmodule ShuttertopWeb.Components do
  @moduledoc """
  Defines a set of web components for use in static and LiveView templates.
  """

  @doc """
  Flash Alert display. For LiveView pages when flash message needs to be shown.

      <.flash_alert flash={@flash} type={:info} />
      <.flash_alert flash={@flash} type={:success} />
      <.flash_alert flash={@flash} type={:warn} />
      <.flash_alert flash={@flash} type={:error} />

  """
  defdelegate flash_alert(assigns), to: ShuttertopWeb.Components.FlashAlert, as: :render
end

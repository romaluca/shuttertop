defmodule ShuttertopWeb do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use ShuttertopWeb, :controller
      use ShuttertopWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def controller do
    quote do
      import Plug.Conn
      use Phoenix.Controller, namespace: ShuttertopWeb
      # use Guardian.Phoenix.Controller
      alias Guardian.Plug.EnsureAuthenticated
      alias Guardian.Plug.EnsurePermissions
      alias ShuttertopWeb.Router.Helpers, as: Routes
      # import Phoenix.LiveView.Controller

      alias Shuttertop.Repo
      import Ecto
      import Ecto.Query, only: [from: 1, from: 2]

      import ShuttertopWeb.Controller.Helpers
      import ShuttertopWeb.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "lib/shuttertop_web/templates", namespace: ShuttertopWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [
          get_csrf_token: 0,
          get_flash: 1,
          get_flash: 2,
          view_module: 1,
          view_template: 1,
          action_name: 1
        ]

      # only: [get_csrf_token: 0, get_flash: 1, get_flash: 2, view_module: 1, action_name: 1]

      # Use all HTML functionality (forms, tags, etc)
      # use Phoenix.HTML
      unquote(view_helpers())
      use Phoenix.HTML.SimplifiedHelpers
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {ShuttertopWeb.LayoutView, "live.html"}

      import ShuttertopWeb.LiveView.Helpers
      unquote(view_helpers())
    end
  end

  def live_page do
    quote do
      use Phoenix.LiveView,
        layout: {ShuttertopWeb.LayoutView, "live.html"}

      import ShuttertopWeb.LiveView.Helpers
      unquote(view_helpers())
      use ShuttertopWeb.LiveView.HelpersPage
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import ShuttertopWeb.LiveView.Helpers
      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import ShuttertopWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import convenience functions for LiveView rendering
      import Phoenix.LiveView.Helpers

      import Phoenix.View

      alias ShuttertopWeb.Router.Helpers, as: Routes
      import ShuttertopWeb.ErrorHelpers
      import ShuttertopWeb.Gettext
      import ShuttertopWeb.ViewHelpers
      import ShuttertopWeb.Helpers.IconHelper
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

defmodule ShuttertopWeb.PageControllerTest do
  use ShuttertopWeb.ConnCase

  import Phoenix.LiveViewTest

  test "GET /contact", %{conn: conn} do
    {:ok, live, html} = live(conn, Routes.live_path(conn, ShuttertopWeb.PageLive.Contact))
    assert html =~ "Contact us"
    assert render(live) =~ "Contact us"
  end
end

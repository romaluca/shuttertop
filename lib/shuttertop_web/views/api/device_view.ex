defmodule ShuttertopWeb.Api.DeviceView do
  use ShuttertopWeb, :view

  require Logger

  def render("index.json", %{devices: devices}) do
    %{data: render_many(devices, ShuttertopWeb.Api.DeviceView, "device.json")}
  end

  def render("show.json", %{device: device}) do
    %{data: render_one(device, ShuttertopWeb.Api.DeviceView, "device.json")}
  end

  def render("device.json", %{device: device}) do
    %{id: device.id, platform: device.platform, token: device.token, user_id: device.user_id}
  end
end

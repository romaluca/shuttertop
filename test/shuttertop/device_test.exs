defmodule Shuttertop.DeviceTest do
  use Shuttertop.DataCase

  # alias Shuttertop.Accounts
  alias Shuttertop.Accounts.{Device}

  @valid_attrs %{platform: "some platform", token: "some token"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Device.changeset(%Device{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Device.changeset(%Device{}, @invalid_attrs)
    refute changeset.valid?
  end
end

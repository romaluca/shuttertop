defmodule Shuttertop.Accounts.Device do
  @moduledoc false

  use TypedEctoSchema
  import Ecto.Changeset
  # alias Shuttertop.Accounts.Device

  typed_schema "devices" do
    field(:platform, :string)
    field(:token, :string)
    belongs_to(:user, Shuttertop.Accounts.User, foreign_key: :user_id)

    timestamps()
  end

  @spec changeset(t()) :: Ecto.Changeset.t()
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:platform, :token])
    |> validate_required([:platform, :token])
    |> unique_constraint(:token, name: :devices_token_platform_index)
  end
end

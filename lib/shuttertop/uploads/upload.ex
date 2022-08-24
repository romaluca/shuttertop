defmodule Shuttertop.Uploads.Upload do
  @moduledoc false

  use TypedEctoSchema
  import Ecto.Changeset

  alias Shuttertop.Accounts.User

  typed_schema "uploads" do
    field(:contest_id, :integer)
    field(:type, :integer)
    field(:expiry_at, :utc_datetime)
    field(:name, :string)
    belongs_to(:user, User)
  end

  @spec changeset(t()) :: Ecto.Changeset.t()
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :contest_id, :type, :expiry_at, :name])
    |> validate_required([:user_id, :type, :expiry_at, :name])
  end
end

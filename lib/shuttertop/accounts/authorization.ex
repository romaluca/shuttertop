defmodule Shuttertop.Accounts.Authorization do
  @moduledoc false

  use TypedEctoSchema
  import Ecto.Changeset
  # alias Shuttertop.Accounts.Authorization

  # alias Comeonin.Bcrypt

  typed_schema "authorizations" do
    field(:provider, :string)
    field(:uid, :string)
    field(:token, :string)
    field(:refresh_token, :string)
    field(:recovery_token, :string)
    field(:expires_at, :integer)
    field(:password, :string, virtual: true)
    field(:password_confirmation, :string, virtual: true)

    belongs_to(:user, Shuttertop.Accounts.User)

    timestamps()
  end

  @spec changeset(t()) :: Ecto.Changeset.t()
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:provider, :uid, :user_id, :token, :refresh_token, :expires_at])
    |> validate_required([:provider, :uid, :user_id, :token])
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:provider_uid)
  end

  @spec create_pw_changeset(t()) :: Ecto.Changeset.t()
  @spec create_pw_changeset(t(), map()) :: Ecto.Changeset.t()
  def create_pw_changeset(model, params \\ %{}) do
    token = Bcrypt.hash_pwd_salt(params["password"])

    model
    |> cast(params, [:password, :password_confirmation])
    |> validate_required([:password, :password_confirmation])
    |> validate_length(:password, min: 8, max: 90)
    |> validate_confirmation(:password)
    |> unique_constraint(:provider_uid)
    |> change(token: token)
  end
end

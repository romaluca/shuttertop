defmodule Shuttertop.Accounts.Invitation do
  use TypedEctoSchema
  import Ecto.Changeset

  alias Shuttertop.Accounts.User

  typed_schema "invitations" do
    field(:email_hash, :string)
    belongs_to(:user, User, foreign_key: :user_id)

    timestamps()
  end

  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:email_hash])
    |> validate_required([:email_hash])
    |> unique_constraint(:invitation, name: :invitation_all_index)
  end
end

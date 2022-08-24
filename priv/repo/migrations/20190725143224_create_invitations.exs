defmodule Shuttertop.Repo.Migrations.CreateInvitations do
  use Ecto.Migration

  def change do
    create table(:invitations) do
      add(:email_hash, :string)
      add(:user_id, references(:users, on_delete: :delete_all))

      timestamps()
    end

    create(
      index(:invitations, [:user_id, :email_hash],
        unique: true,
        name: :invitation_all_index
      )
    )
  end
end

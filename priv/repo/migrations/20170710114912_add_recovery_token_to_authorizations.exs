defmodule Shuttertop.Repo.Migrations.AddRecoveryTokenToAuthorizations do
  use Ecto.Migration

  def change do
    alter table(:authorizations) do
      add(:recovery_token, :string)
    end
  end
end

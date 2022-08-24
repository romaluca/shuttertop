defmodule Shuttertop.Repo.Migrations.AddBlockedUsers do
  use Ecto.Migration

  def change do
    create table(:blocked_users, primary_key: false) do
      add(:user_id, references(:users, on_delete: :delete_all), primary_key: true)
      add(:user_to_id, references(:users, on_delete: :delete_all), primary_key: true)

      timestamps()
    end
  end
end

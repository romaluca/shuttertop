defmodule Shuttertop.Repo.Migrations.AddUserToUsers do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add(:user_to_id, references(:comments, on_delete: :delete_all))
    end

    create(index(:comments, [:user_id, :user_to_id]))
  end
end

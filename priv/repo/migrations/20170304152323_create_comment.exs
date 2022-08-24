defmodule Shuttertop.Repo.Migrations.CreateComment do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add(:body, :text)
      add(:photo_id, references(:photos, on_delete: :delete_all))
      add(:user_id, references(:users, on_delete: :delete_all))

      timestamps()
    end

    create(index(:comments, [:photo_id]))
    create(index(:comments, [:user_id]))
  end
end

defmodule Shuttertop.Repo.Migrations.CreateTopic do
  use Ecto.Migration

  def change do
    create table(:topics) do
      add(:contest_id, references(:contests, on_delete: :delete_all))
      add(:photo_id, references(:photos, on_delete: :delete_all))
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:user_to_id, references(:users, on_delete: :delete_all))
      add(:last_comment_id, references(:comments, on_delete: :delete_all))
    end

    create(index(:topics, [:last_comment_id]))
    create(index(:topics, [:user_id, :user_to_id]))
    create(index(:topics, [:contest_id]))
    create(index(:topics, [:photo_id]))
  end
end

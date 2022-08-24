defmodule Shuttertop.Repo.Migrations.CreateActivity do
  use Ecto.Migration

  def change do
    create table(:activities) do
      add(:points, :integer)
      add(:type, :integer)
      add(:user_to_id, references(:users, on_delete: :delete_all))
      add(:photo_id, references(:photos, on_delete: :delete_all))
      add(:contest_id, references(:contests, on_delete: :delete_all))
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:comment_id, references(:comments, on_delete: :delete_all))

      timestamps()
    end

    create(index(:activities, [:user_to_id]))
    create(index(:activities, [:photo_id]))
    create(index(:activities, [:contest_id]))
    create(index(:activities, [:user_id]))
    create(index(:activities, [:comment_id]))
  end
end

defmodule Shuttertop.Repo.Migrations.CreatePhoto do
  use Ecto.Migration

  def change do
    create table(:photos) do
      add(:slug, :citext, null: false)
      add(:name, :string, size: 100)
      add(:position, :integer, null: false)
      add(:is_visibile, :boolean, default: false, null: false)
      add(:upload, :string, null: false)
      add(:votes_count, :integer, default: 0, null: false)
      add(:comments_count, :integer, default: 0, null: false)
      add(:contest_id, references(:contests, on_delete: :delete_all))
      add(:user_id, references(:users, on_delete: :delete_all))

      timestamps()
    end

    create(index(:photos, [:contest_id]))
    create(index(:photos, [:user_id]))
    create(index(:photos, [:contest_id, :user_id], unique: true))
    create(index(:photos, [:slug], unique: true))
  end
end

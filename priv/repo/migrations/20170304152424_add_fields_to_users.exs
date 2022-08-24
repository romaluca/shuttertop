defmodule Shuttertop.Repo.Migrations.AddFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:slug, :citext, null: false)
      add(:upload, :string)
      add(:score, :integer, default: 0, null: false)
      add(:photos_count, :integer, default: 0, null: false)
      add(:notifies_enabled, :boolean, default: true, null: true)
      add(:comments_count, :integer, default: 0, null: false)
      add(:contests_count, :integer, default: 0, null: false)
      add(:followers_count, :integer, default: 0, null: false)
      add(:winner_count, :integer, default: 0, null: false)
    end

    create(index(:users, [:slug], unique: true))
  end
end

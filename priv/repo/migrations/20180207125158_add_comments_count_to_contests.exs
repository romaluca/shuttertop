defmodule Shuttertop.Repo.Migrations.AddCommentsCountToContests do
  use Ecto.Migration

  def change do
    alter table(:contests) do
      add(:comments_count, :integer, default: 0, null: false)
    end
  end
end

defmodule Shuttertop.Repo.Migrations.AddLevelToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:level, :integer, default: 1, null: false)
    end

    execute("UPDATE users SET level = 2 WHERE score > 1000")
  end
end

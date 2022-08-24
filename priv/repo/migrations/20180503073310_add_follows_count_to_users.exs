defmodule Shuttertop.Repo.Migrations.AddFollowsCountToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:follows_user_count, :integer, default: 0)
      add(:follows_contest_count, :integer, default: 0)
    end
  end
end

defmodule Shuttertop.Repo.Migrations.AddNotifyContestCreatedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:notify_contest_created, :integer, default: 0)
    end
  end
end

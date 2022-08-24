defmodule Shuttertop.Repo.Migrations.AddNotifyCountToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:notify_count, :integer, default: 0)
    end
  end
end

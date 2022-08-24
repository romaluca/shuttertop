defmodule Shuttertop.Repo.Migrations.AddNotifyMessageCountToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:notify_message_count, :integer, default: 0)
    end
  end
end

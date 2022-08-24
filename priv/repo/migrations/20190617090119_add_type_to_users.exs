defmodule Shuttertop.Repo.Migrations.AddTypeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:type, :integer, default: 0, null: false)
    end

    execute("UPDATE users SET type = 2 WHERE is_admin = true")
    execute("UPDATE users SET type = 1 WHERE email like '%@cloudtestlabaccounts.com'")

    alter table(:users) do
      remove(:is_admin)
    end
  end
end

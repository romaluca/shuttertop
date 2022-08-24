defmodule Shuttertop.Repo.Migrations.AddIsAdminToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:is_admin, :boolean, default: false, null: false)
    end

    execute("UPDATE users SET is_admin = true")
  end
end

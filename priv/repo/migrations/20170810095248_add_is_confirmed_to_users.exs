defmodule Shuttertop.Repo.Migrations.AddIsConfirmedToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:is_confirmed, :boolean, default: false, null: false)
    end
  end
end

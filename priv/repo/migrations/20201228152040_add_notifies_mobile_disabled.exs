defmodule Shuttertop.Repo.Migrations.AddNotifiesMobileDisabled do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:notifies_mobile_disabled, :integer, default: 0, null: false)
    end
  end
end

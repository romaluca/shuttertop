defmodule Shuttertop.Repo.Migrations.AddLanguageToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:language, :string, default: "en", null: false, size: 2)
    end
  end
end

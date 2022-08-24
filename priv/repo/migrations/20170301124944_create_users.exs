defmodule Shuttertop.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION citext;")

    create table(:users) do
      add(:name, :citext)
      add(:email, :citext)

      timestamps()
    end

    create(index(:users, [:email], unique: true))
    create(index(:users, [:name], unique: true))
  end
end

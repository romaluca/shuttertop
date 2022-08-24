defmodule Shuttertop.Repo.Migrations.CreateDevice do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add(:platform, :string)
      add(:token, :string)
      add(:user_id, references(:users, on_delete: :delete_all))

      timestamps()
    end

    create(index(:devices, [:user_id]))
    create(index(:devices, [:token, :platform], unique: true))
  end
end

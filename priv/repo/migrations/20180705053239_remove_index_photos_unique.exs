defmodule Shuttertop.Repo.Migrations.RemoveIndexPhotosUnique do
  use Ecto.Migration

  def change do
    drop(index(:photos, [:contest_id, :user_id], unique: true))
    create(index(:photos, [:contest_id, :user_id]))
  end
end

defmodule Shuttertop.Repo.Migrations.CreateEvent do
  use Ecto.Migration

  def change do
    create table(:events) do
      add(:type, :integer)
      add(:week, :integer)
      add(:year, :integer)
      add(:contest_id, references(:contests, on_delete: :delete_all))
      add(:photo_id, references(:photos, on_delete: :delete_all))
    end

    create(unique_index(:events, [:type, :week, :year]))
  end
end

defmodule Shuttertop.Repo.Migrations.AddWinnerIdToContests do
  use Ecto.Migration

  def change do
    alter table(:contests) do
      add(:winner_id, references(:photos, on_delete: :delete_all))
    end

    create(index(:contests, [:winner_id]))
  end
end

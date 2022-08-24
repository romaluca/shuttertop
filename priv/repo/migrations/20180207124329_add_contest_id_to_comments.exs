defmodule Shuttertop.Repo.Migrations.AddContestIdToComments do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add(:contest_id, references(:contests, on_delete: :delete_all))
    end

    create(index(:comments, [:contest_id]))
  end
end

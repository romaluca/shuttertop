defmodule Shuttertop.Repo.Migrations.AddFieldsToContests do
  use Ecto.Migration

  def change do
    alter table(:contests) do
      add(:contest_id, references(:contests, on_delete: :nilify_all))
    end
  end
end

defmodule Shuttertop.Repo.Migrations.UpdateContestTable do
  use Ecto.Migration

  def change do
    alter table(:contests) do
      add(:edition, :integer, default: 1)
    end
  end
end

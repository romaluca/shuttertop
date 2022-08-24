defmodule Shuttertop.Repo.Migrations.AddActivityWinIndex do
  use Ecto.Migration

  def change do
    create(
      index(:activities, [:user_id, :contest_id],
        where: "type = 8",
        unique: true,
        name: :user_win_activities_index
      )
    )
  end
end

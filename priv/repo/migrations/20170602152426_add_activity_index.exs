defmodule Shuttertop.Repo.Migrations.AddActivityIndex do
  use Ecto.Migration

  def change do
    create(
      index(:activities, [:photo_id, :user_id],
        where: "type = 7",
        unique: true,
        name: :vote_activities_index
      )
    )

    create(
      index(:activities, [:contest_id, :user_id],
        where: "type = 1",
        unique: true,
        name: :contest_follow_activities_index
      )
    )

    create(
      index(:activities, [:user_id, :user_to_id],
        where: "type = 0",
        unique: true,
        name: :user_follow_activities_index
      )
    )
  end
end

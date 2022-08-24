defmodule Shuttertop.Repo.Migrations.CreateActivitiesUsers do
  use Ecto.Migration

  def change do
    create table(:activities_users) do
      add(:activity_id, references(:activities, on_delete: :delete_all))
      add(:user_id, references(:users, on_delete: :delete_all))
    end

    create(
      index(:activities_users, [:activity_id, :user_id],
        unique: true,
        name: :activities_users_index
      )
    )
  end
end

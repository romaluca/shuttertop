defmodule Shuttertop.Repo.Migrations.AddIdxToTopic do
  use Ecto.Migration

  def change do
    create(
      index(:topics, [:user_id, :user_to_id, :photo_id, :contest_id],
        unique: true,
        name: :topic_all_index
      )
    )
  end
end

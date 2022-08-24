defmodule Shuttertop.Repo.Migrations.AddTopicIdToComments do
  use Ecto.Migration
  import Ecto.{Query, Changeset}, warn: false
  alias Shuttertop.Repo

  def change do
    Repo.update_all(Shuttertop.Contests.Contest, set: [comments_count: 0])
    Repo.update_all(Shuttertop.Photos.Photo, set: [comments_count: 0])
    Repo.delete_all(Shuttertop.Posts.Comment)
    Repo.delete_all(Shuttertop.Posts.Topic)
    drop(index(:comments, [:contest_id]))
    drop(index(:comments, [:photo_id]))
    drop(index(:comments, [:user_id, :user_to_id]))

    alter table(:comments) do
      remove(:contest_id)
      remove(:photo_id)
      remove(:user_to_id)
    end

    drop(index(:activities, [:comment_id]))

    alter table(:activities) do
      remove(:comment_id)
    end

    alter table(:comments) do
      add(:topic_id, references(:topics, on_delete: :delete_all), null: false)
    end

    create(index(:comments, [:topic_id]))
  end
end

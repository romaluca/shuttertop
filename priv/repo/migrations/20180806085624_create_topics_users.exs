defmodule Shuttertop.Repo.Migrations.CreateTopicsUsers do
  use Ecto.Migration

  def change do
    create table(:topics_users) do
      add(:topic_id, references(:topics, on_delete: :delete_all))
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:last_read_at, :utc_datetime)
    end

    create(index(:topics_users, [:topic_id, :user_id], unique: true, name: :topics_users_index))
  end
end

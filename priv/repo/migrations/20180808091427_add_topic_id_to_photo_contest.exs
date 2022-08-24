defmodule Shuttertop.Repo.Migrations.AddTopicIdToPhotoContest do
  use Ecto.Migration

  def change do
    alter table(:contests) do
      add(:topic_id, references(:topics, on_delete: :delete_all))
    end

    create(index(:contests, [:topic_id]))

    alter table(:photos) do
      add(:topic_id, references(:topics, on_delete: :delete_all))
    end

    create(index(:photos, [:topic_id]))
  end
end

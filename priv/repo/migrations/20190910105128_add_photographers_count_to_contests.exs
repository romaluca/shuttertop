defmodule Shuttertop.Repo.Migrations.AddUsersCountToContests do
  use Ecto.Migration

  def change do
    alter table(:contests) do
      add(:photographers_count, :integer, default: 0, null: false)
    end

    execute("update contests
        set photographers_count = (select COUNT(DISTINCT photos.user_id)
        from photos  
        where photos.contest_id = contests.id)")
  end
end

defmodule Shuttertop.Repo.Migrations.CreateContest do
  use Ecto.Migration

  def change do
    create table(:contests) do
      add(:slug, :citext, null: false)
      add(:name, :citext, null: false)
      add(:description, :text)
      add(:photos_count, :integer, default: 0)
      add(:category_id, :integer, default: 0)
      add(:url, :string)
      add(:start_at, :utc_datetime)
      add(:expiry_at, :utc_datetime)
      add(:is_public, :boolean, default: true, null: false)
      add(:score, :integer)
      add(:is_expired, :boolean, default: false, null: false)
      add(:is_visible, :boolean, default: true, null: false)
      add(:upload, :string)
      add(:followers_count, :integer, default: 0)
      add(:user_id, references(:users, on_delete: :delete_all))

      timestamps()
    end

    create(index(:contests, [:user_id]))
    create(index(:contests, [:slug], unique: true))
  end
end

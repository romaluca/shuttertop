defmodule Shuttertop.Repo.Migrations.CreateUpload do
  use Ecto.Migration

  def change do
    create table(:uploads) do
      add(:user_id, :integer)
      add(:contest_id, :integer)
      add(:type, :integer)
      add(:expiry_at, :utc_datetime)
      add(:name, :string)
    end
  end
end

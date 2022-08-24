defmodule Shuttertop.Repo.Migrations.UpdatePhotoTable do
  use Ecto.Migration

  def change do
    alter table(:photos) do
      add(:width, :integer)
      add(:height, :integer)
    end
  end
end

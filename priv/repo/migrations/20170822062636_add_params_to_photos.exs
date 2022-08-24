defmodule Shuttertop.Repo.Migrations.AddParamsToPhotos do
  use Ecto.Migration

  def change do
    alter table(:photos) do
      add(:model, :string)
      add(:f_number, :float)
      add(:focal_length, :string)
      add(:photographic_sensitivity, :integer)
      add(:exposure_time, :float)
      add(:lat, :float)
      add(:lng, :float)
    end
  end
end

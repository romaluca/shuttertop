defmodule Shuttertop.Repo.Migrations.AddMetaToPhotos do
  use Ecto.Migration

  def change do
    alter table(:photos) do
      add(:meta, :map)
    end

    execute(
      "UPDATE photos SET meta = meta || jsonb_build_object('model', model, 'focal_length', focal_length,
      'photographic_sensitivity', photographic_sensitivity,
      'exposure_time', exposure_time, 'lat', lat, 'lng', lng) where meta is null"
    )
  end
end

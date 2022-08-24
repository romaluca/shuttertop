defmodule Shuttertop.Repo.Migrations.AddUserCountryCode do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:country_code, :string)
    end
  end
end

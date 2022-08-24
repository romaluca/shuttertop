defmodule Shuttertop.Uploads do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  require Logger

  alias ExAws.Config
  alias ExAws.S3
  alias Shuttertop.Accounts.{User}
  alias Shuttertop.Repo

  alias Shuttertop.Uploads.Upload

  @spec get_upload_by!(Keyword.t() | map) :: Upload.t()
  def get_upload_by!(list) do
    Repo.get_by!(Upload, list)
  end

  @spec delete_upload(Upload.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def delete_upload(upload) do
    Repo.delete(upload)
  end

  @spec delete_upload(binary, User.t()) :: {integer(), nil | [term()]}
  def delete_upload(upload_name, user) do
    Repo.delete_all(from(p in Upload, where: p.name == ^upload_name and p.user_id == ^user.id))
  end

  @spec create_upload(User.t() | nil) :: Upload.t()
  @spec create_upload(map, User.t() | nil) :: Upload.t()
  def create_upload(attrs \\ %{}, user) do
    user
    |> Ecto.build_assoc(:uploads,
      expiry_at:
        Timex.now()
        |> Timex.shift(minutes: 5)
        |> Timex.to_datetime()
        |> DateTime.truncate(:second)
    )
    |> Upload.changeset(attrs)
    |> Repo.insert!()
  end

  @spec check_uploads() :: any
  def check_uploads do
    config = Config.new(:s3, %{region: "eu-west-1"})
    bucket = "img.shuttertop.com"

    uploads = Repo.all(from(c in Upload, where: c.expiry_at < ^Timex.now(), select: [:id, :name]))

    for u <- uploads do
      Logger.info("----   Delete upload: #{u.id} #{u.name}")

      bucket
      |> S3.delete_object(u.name)
      |> ExAws.request(config)

      Repo.delete(u)
    end
  end
end

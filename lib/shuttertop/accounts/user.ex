defmodule Shuttertop.Accounts.User do
  @moduledoc false

  use TypedEctoSchema
  import Ecto.Changeset
  require Shuttertop.Constants

  alias Shuttertop.Accounts
  alias Shuttertop.Accounts.{Authorization, BlockedUser, Device, Invitation}
  alias Shuttertop.Activities.Activity
  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Uploads.Upload
  alias Shuttertop.Posts.{Comment, Topic, TopicUser}

  @derive {Swoosh.Email.Recipient, name: :name, address: :email}

  typed_schema "users" do
    field(:name, :string)
    field(:email, :string)
    field(:slug, :string)
    field(:upload, :string)
    field(:country_code, :string)
    field(:level, :integer, default: 1)
    field(:score, :integer, default: 0)
    field(:score_partial, :integer, default: 0, virtual: true)
    field(:photos_count, :integer, default: 0)
    field(:notifies_enabled, :boolean, default: true)
    field(:notifies_mobile_disabled, :integer, default: 0)
    field(:comments_count, :integer, default: 0)
    field(:contests_count, :integer, default: 0)
    field(:followers_count, :integer, default: 0)
    field(:follows_user_count, :integer, default: 0)
    field(:follows_contest_count, :integer, default: 0)
    field(:winner_count, :integer, default: 0)
    field(:notify_count, :integer, default: 0)
    field(:notify_message_count, :integer, default: 0)
    field(:notify_contest_created, :integer, default: 0)
    field(:type, :integer, default: 0)
    field(:language, :string, default: "en")
    field(:is_confirmed, :boolean, default: false)
    field(:in_progress, :integer, default: 0, virtual: true)
    field(:topic_id, :integer, null: true, virtual: true)

    has_many(:authorizations, Authorization, on_delete: :delete_all)
    has_many(:contests, Contest, on_delete: :delete_all)
    has_many(:photos, Photo, on_delete: :delete_all)
    has_many(:activities, Activity, on_delete: :delete_all)
    has_many(:uploads, Upload, on_delete: :delete_all)
    has_many(:invitations, Invitation, on_delete: :delete_all)

    has_many(
      :activities_to,
      Activity,
      foreign_key: :user_to_id,
      on_delete: :delete_all
    )

    has_many(:devices, Device, on_delete: :delete_all)
    has_many(:comments, Comment, on_delete: :delete_all)
    many_to_many(:topics_following, Topic, join_through: "topics_users", on_delete: :delete_all)
    has_many(:topics_users, TopicUser, on_delete: :delete_all)
    has_many(:blocked_users, BlockedUser, foreign_key: :user_id, on_delete: :delete_all)
    has_many(:blocked_by_users, BlockedUser, foreign_key: :user_to_id, on_delete: :delete_all)

    timestamps()
  end

  def fields_basic(), do: [:id, :name, :slug, :upload, :score, :winner_count]

  @spec registration_changeset(t()) :: Ecto.Changeset.t()
  @spec registration_changeset(t(), map()) :: Ecto.Changeset.t()
  def registration_changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email, :country_code])
    |> put_change(:type, Const.user_type_newbie())
    |> validate_required([:name, :email])
    |> update_change(:name, &String.trim/1)
    |> update_change(:email, &String.trim/1)
    |> validate_length(:name, min: 4)
    |> generate_slug()
  end

  @spec form_registration_changeset(t()) :: Ecto.Changeset.t()
  @spec form_registration_changeset(t(), map()) :: Ecto.Changeset.t()
  def form_registration_changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email, :country_code, :language])
    |> cast_assoc(
      :authorizations,
      required: true,
      with: &Authorization.create_pw_changeset/2
    )
    |> put_change(:type, Const.user_type_newbie())
    |> validate_required([:name, :email])
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,63}$/)
    |> update_change(:name, &String.trim/1)
    |> update_change(:email, &String.trim/1)
    |> validate_length(:name, min: 4)
    |> unique_constraint(:email)
    |> unique_constraint(:name)
    |> put_identity_data()
    |> generate_slug()
  end

  @spec changeset(t()) :: Ecto.Changeset.t()
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email, :upload, :country_code, :notifies_enabled, :language])
    |> changeset_update()
  end

  @spec changeset_admin(t()) :: Ecto.Changeset.t()
  @spec changeset_admin(t(), map()) :: Ecto.Changeset.t()
  def changeset_admin(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email, :upload, :country_code, :notifies_enabled, :language, :type])
    |> changeset_update()
  end

  @spec changeset_update(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp changeset_update(changeset) do
    changeset
    |> validate_required([:name, :email])
    |> update_change(:name, &String.trim/1)
    |> update_change(:email, &String.trim/1)
    |> validate_format(:email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,63}$/)
    |> validate_length(:name, min: 4)
    |> unique_constraint(:name)
    |> unique_constraint(:email)
  end

  @spec unique_slug({any, binary}) :: binary()
  defp unique_slug({_, nil}), do: nil

  defp unique_slug({_, title}) do
    title = Slugger.slugify_downcase(title)
    exists = Accounts.get_user_by(slug: title)

    if exists do
      unique_slug({:error, "#{title}-#{:rand.uniform(99999)}"})
    else
      title
    end
  end

  @spec generate_slug(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp generate_slug(changeset) do
    case fetch_field(changeset, :slug) do
      {:data, nil} ->
        slug = unique_slug(fetch_field(changeset, :name))
        put_change(changeset, :slug, slug)

      _ ->
        changeset
    end
  end

  @spec put_identity_data(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp put_identity_data(changeset) do
    if changeset.valid? do
      extras = %{provider: "identity", uid: get_field(changeset, :email)}

      identity_auth =
        changeset
        |> get_field(:authorizations)
        |> Enum.map(&Map.merge(&1, extras))

      put_assoc(changeset, :authorizations, identity_auth)
    else
      changeset
    end
  end
end

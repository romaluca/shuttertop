defmodule Shuttertop.Contests.Contest do
  @moduledoc false

  use TypedEctoSchema
  import Ecto.Changeset
  require Logger
  alias Shuttertop.Photos.Photo
  alias Shuttertop.Events.Event

  alias Shuttertop.Accounts.User
  alias Shuttertop.Activities.Activity
  alias Shuttertop.Posts.Topic

  # @derive {Phoenix.Param, key: :slug}
  typed_schema "contests" do
    field(:name, :string)
    field(:slug, :string)
    field(:description, :string)
    field(:photos_count, :integer, default: 0)
    field(:category_id, :integer, default: 0)
    field(:url, :string)
    field(:start_at, :utc_datetime)
    field(:expiry_days, :integer, virtual: true, default: 0)
    field(:expiry_at, :utc_datetime)
    field(:is_public, :boolean, default: true)
    field(:score, :integer, default: 0)
    field(:is_expired, :boolean, default: false)
    field(:is_visible, :boolean, default: true)
    field(:upload, :string)
    field(:edition, :integer, default: 1)
    field(:followers_count, :integer, default: 0)
    field(:photographers_count, :integer, default: 0)
    field(:comments_count, :integer, default: 0)

    belongs_to(:winner, Photo)
    belongs_to(:user, User)
    belongs_to(:topic, Topic)
    belongs_to(:contest, __MODULE__)

    has_one(:user_photo, Photo)

    has_many(:activities, Activity, on_delete: :delete_all)
    has_many(:events, Event, on_delete: :delete_all)
    has_many(:photos, Photo, on_delete: :delete_all)
    has_many(:contests, __MODULE__, on_delete: :nilify_all)

    timestamps()
  end

  def fields_basic,
    do: [
      :id,
      :name,
      :slug,
      :expiry_at,
      :category_id,
      :upload,
      :comments_count,
      :photos_count,
      :followers_count,
      :photographers_count,
      :user_id,
      :is_expired
    ]

  @spec changeset(t()) :: Ecto.Changeset.t()
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = struct, params \\ %{}) do
    params = param_expiry(params)

    struct
    |> cast(params, [
      :name,
      :description,
      :category_id,
      :url,
      :expiry_at,
      :upload,
      :expiry_days,
      :contest_id
    ])
    |> validate_required([:name, :category_id, :expiry_at, :expiry_days])
    |> update_change(:name, &String.trim/1)
    |> validate_expiry_at
  end

  @spec changeset_update(t()) :: Ecto.Changeset.t()
  @spec changeset_update(t(), map()) :: Ecto.Changeset.t()
  def changeset_update(%__MODULE__{} = struct, params \\ %{}) do
    params = param_expiry(params)

    struct
    |> cast(params, [
      :name,
      :description,
      :category_id,
      :url,
      :expiry_at,
      :upload,
      :expiry_days,
      :contest_id
    ])
    |> validate_required([:name, :category_id, :expiry_at, :expiry_days])
    |> validate_expiry_change(struct.expiry_at)
    |> validate_expiry_at
  end

  @spec validate_expiry_change(Changeset.t(), DateTime.t()) :: Changeset.t()
  defp validate_expiry_change(changeset, old_expiry_at) do
    new_expiry_at = get_change(changeset, :expiry_at)

    if !is_nil(new_expiry_at) and Date.compare(Timex.now(), old_expiry_at) == :gt do
      add_error(changeset, :expiry_at, "Contest terminato")
    else
      changeset
    end
  end

  @spec validate_expiry_at(Changeset.t()) :: Changeset.t()
  defp validate_expiry_at(changeset) do
    expiry_at = get_change(changeset, :expiry_at)
    tomorrow = Timex.shift(Timex.today(), days: 1)

    if !is_nil(expiry_at) and Date.compare(tomorrow, expiry_at) == :gt do
      add_error(changeset, :expiry_at, "Data di scadenza non valida")
    else
      changeset
    end
  end

  defp param_expiry(%{} = params) do
    expiry_days = to_string(params["expiry_days"])

    case expiry_days do
      "0" -> param_date(params, "expiry_at")
      _ -> param_expiry_days(params, expiry_days)
    end
  end

  @spec param_date(map, binary) :: map
  defp param_date(%{} = params, param) do
    try do
      date = params[param]

      if date && is_binary(date) do
        d = date <> " 23:59:59"

        case Timex.parse(d, "%Y-%m-%d %H:%M:%S", :strftime) do
          {:ok, d} -> Map.put(params, param, d)
          {_, _} -> params
        end
      else
        params
      end
    rescue
      _ in RuntimeError ->
        # Logger.error "Got error param_date: #{e.message}"
        params
    end
  end

  defp param_expiry_days(%{} = params, expiry_days) do
    days =
      case expiry_days do
        "1" -> 7
        "2" -> 14
        "3" -> 30
        _ -> nil
      end

    if days do
      expiry_at = Timex.now() |> Timex.shift(days: days) |> Timex.end_of_day()
      Map.put(params, "expiry_at", expiry_at)
    else
      params
    end
  end
end

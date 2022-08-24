defmodule ShuttertopWeb.Controller.Helpers do
  @moduledoc false

  import Plug.Conn
  require Shuttertop.Constants

  alias Shuttertop.Accounts.User
  alias Shuttertop.Contests.Contest
  alias Shuttertop.Constants, as: Const
  alias Shuttertop.Photos.Photo

  require Logger

  def redirect_back(conn, alternative \\ "/") do
    path =
      conn
      |> get_req_header("referer")
      |> referrer

    path || alternative
  end

  @spec contests_params(map, map) :: {:error, :not_found} | {:ok, map}
  def contests_params(init_params, params) do
    p =
      case {params["type"], params["user_id"]} do
        {"joined", user_id} ->
          %{joined: user_id || init_params[:user_id]}

        {"following", user_id} ->
          %{following: user_id || init_params[:user_id]}

        {_, user_id} when user_id != nil ->
          %{user_id: user_id}

        {_, _} ->
          %{}
      end

    g =
      if is_nil(params["all"]) do
        %{expired: !is_nil(params["expired"])}
      else
        %{}
      end

    init_params =
      cond do
        !is_nil(params["expired"]) ->
          Map.put(init_params, :order, :expiry)

        is_nil(params["order"]) && is_nil(params[:order]) ->
          Map.put(init_params, :order, :news)

        is_nil(params[:order]) ->
          Map.put(init_params, :order, String.to_existing_atom(params["order"]))

        true ->
          init_params
      end

    init_params
    |> Map.merge(p)
    |> Map.merge(g)
    |> concat_element(params, "category_id")
    |> concat_element(params, "search")
    |> concat_params(params)
  end

  @spec photos_params(map, map) :: {:error, :not_found} | {:ok, map}
  def photos_params(init_params, params) do
    p =
      case params["type"] do
        "wins" ->
          %{wins: true}

        "in_progress" ->
          %{not_expired: true}

        _ ->
          %{}
      end

    p = Map.merge(init_params, p)

    p
    |> concat_element(params, "contest_id")
    |> concat_element(params, "user_id")
    |> concat_element_atom(params, "order")
    |> concat_params(params)
  end

  @spec users_params(any, map) :: {:error, :not_found} | {:ok, map}
  def users_params(init_params, params) do
    init_params =
      if is_nil(params[:order]) && !is_nil(params["order"]) do
        Map.put(init_params, :order, String.to_existing_atom(params["order"]))
      else
        init_params
      end

    init_params
    |> concat_element(params, "emails")
    |> concat_element(params, "days")
    |> concat_element_atom(params, "order")
    |> concat_element(params, "blocked")
    |> concat_element(params, "search")
    |> concat_params(params)
  end

  @spec topics_params(any, map) :: {:error, :not_found} | {:ok, map}
  def topics_params(init_params, params) do
    init_params
    |> concat_element_atom(params, "order")
    |> concat_element(params, "user_id")
    |> concat_element(params, "search")
    |> concat_params(params)
  end

  @spec activities_params(any, map) :: {:error, :not_found} | {:ok, map}
  def activities_params(init_params, params) do
    init_params
    |> concat_element_atom(params, "order")
    |> concat_element(params, "user_id")
    |> concat_element(params, "contest_id")
    |> concat_element(params, "in_progress")
    |> concat_element(params, "search")
    |> concat_element(params, "not_booked")
    |> concat_params(params)
  end

  @spec concat_element_atom(any, nil | maybe_improper_list | map, binary) :: any
  def concat_element_atom(init_params, params, key) do
    key_atom = String.to_existing_atom(key)

    if !is_nil(params[key]) && is_nil(init_params[key_atom]) do
      Map.put(init_params, key_atom, String.to_existing_atom(params[key]))
    else
      init_params
    end
  end

  @spec concat_element(any, nil | maybe_improper_list | map, binary) :: any
  def concat_element(init_params, params, key) do
    key_atom = String.to_existing_atom(key)

    if !is_nil(params[key]) && is_nil(init_params[key_atom]) do
      Map.put(init_params, key_atom, params[key])
    else
      init_params
    end
  end

  @spec concat_params(any, map) :: {:error, :not_found} | {:ok, map}
  def concat_params(params, all_params) do
    t = {"page", "page_size", "limit"}
    string_key_map = Map.take(all_params, Tuple.to_list(t))

    p =
      for {key, val} <- string_key_map, into: %{} do
        key_atom = String.to_existing_atom(key)

        value_int =
          cond do
            is_binary(val) ->
              {v, _} = Integer.parse(val)

              v

            true ->
              val
          end

        {key_atom, value_int}
      end

    if (p[:page] || 1) < 1 do
      {:error, :not_found}
    else
      {:ok, Map.merge(params, p)}
    end
  end

  @spec is_admin(%User{}) :: boolean
  def is_admin(user) do
    user.type == Const.user_type_admin()
  end

  defp referrer([]), do: nil
  defp referrer([h | _]), do: h

  def slug_path(%Contest{} = contest), do: "#{contest.id}-#{contest.slug}"
  def slug_path(%User{} = user), do: "#{user.id}-#{user.slug}"
  def slug_path(%Photo{} = photo), do: "#{photo.id}-#{photo.slug}"
end

defmodule ShuttertopWeb.Api.FallbackController do
  use ShuttertopWeb, :controller

  require Logger

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ShuttertopWeb.Api.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, schema, %Ecto.Changeset{} = changeset, _})
      when schema == :contest or schema == :photo or schema == :activity do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ShuttertopWeb.Api.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render("auth_required.json")
  end

  def call(conn, {:error, :expired_contest}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render("expired_contest.json")
  end

  def call(conn, {:error, :one_photo_per_contest}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render("one_photo_per_contest.json")
  end

  def call(conn, {:error, :password_is_null}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render("wrong_credentials.json")
  end

  def call(conn, {:error, :wrong_credentials}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render("wrong_credentials.json")
  end

  def call(conn, {:error, :password_does_not_match}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render("wrong_credentials.json")
  end

  def call(conn, {:error, :password_confirmation_does_not_match}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render("wrong_credentials.json")
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, x}) when is_binary(x) do
    conn
    |> put_status(:bad_request)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render("bad_request.json", error: x)
  end

  def call(conn, {:error, %{} = params}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(params)
  end

  def call(conn, _) do
    conn
    |> put_status(:unprocessable_entity)
  end
end

defmodule ShuttertopWeb.FallbackController do
  use ShuttertopWeb, :controller

  require Logger

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render(:"403")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render(:"401")
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :wrong_credentials}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(ShuttertopWeb.ErrorView)
    |> render("wrong_credentials.json")
  end
end

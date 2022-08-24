defmodule ShuttertopWeb.ErrorView do
  use ShuttertopWeb, :view
  use JaSerializer.PhoenixView

  alias JaSerializer.ErrorSerializer

  require Logger

  def render("bad_request.json", %{error: error}) do
    %{title: error, code: 400}
    |> ErrorSerializer.format()
  end

  def render("failed_credentials.json", %{error: error}) do
    %{error: error}
  end

  def render("changeset.json", %{changeset: changeset}) do
    errors =
      Enum.map(changeset.errors, fn {field, {message, values}} ->
        %{
          source: %{pointer: "/data/attributes/#{field}"},
          title: "Invalid Attribute",
          detail: render_detail({message, values}),
          slug: if(is_nil(values), do: nil, else: values[:slug])
        }
      end)

    %{errors: errors}
  end

  def render("400.json", _assigns) do
    %{title: "Bad request", code: 400}
  end

  def render("400.html", _assigns) do
    "Bad request"
  end

  def render("401.json", %{message: message}) do
    %{title: "Unauthorized1", code: 401, message: message}
  end

  def render("401.json", _assigns) do
    %{title: "Unauthorized2", code: 401}
  end

  def render("403.json", _assigns) do
    %{title: "Forbidden", code: 403}
    |> ErrorSerializer.format()
  end

  def render("404.html", _assigns) do
    render("404_page.html", %{})
  end

  def render("404.json", _assigns) do
    %{title: "Page not found", code: 404}
    |> ErrorSerializer.format()
  end

  def render("422.json", _assigns) do
    %{title: "Unprocessable entity", code: 422}
    |> ErrorSerializer.format()
  end

  def render("500.html", _assigns) do
    "Internal server error"
  end

  def render("500.json", _assigns) do
    %{title: "Internal Server Error", code: 500}
    |> ErrorSerializer.format()
  end

  def render("505.html", _assigns) do
    "Internal server error"
  end

  def render("auth_required.json", _assigns) do
    %{error: true}
  end

  def render("wrong_credentials.json", _assigns) do
    %{error: true}
  end

  def render("expired_contest.json", _assigns) do
    %{title: "Expired contest", code: 401}
  end

  def render("one_photo_per_contest.json", _assigns) do
    %{error: true, title: "You can insert one photo per contest", code: 422}
  end

  def template_not_found(_template, assigns) do
    render("500.html", assigns)
  end

  defp render_detail({message, values}) do
    Enum.reduce(values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
  end
end

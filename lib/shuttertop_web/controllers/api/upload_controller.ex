defmodule ShuttertopWeb.Api.UploadController do
  use ShuttertopWeb, :controller

  alias ExAws.Config
  alias ExAws.S3
  alias Shuttertop.{Contests, Uploads}
  alias Shuttertop.Guardian.Plug

  require Logger

  plug(Guardian.Plug.EnsureAuthenticated)
  action_fallback(ShuttertopWeb.Api.FallbackController)

  def presign(conn, %{"now" => now, "id" => id, "schema" => "contest"}) do
    current_user = Plug.current_resource(conn)

    if is_admin(current_user) do
      Contests.get_contest_by!(id: id)
    else
      Contests.get_contest_by!(user_id: current_user.id, id: id)
    end

    Uploads.create_upload(%{type: 1, name: "#{now}_C_#{id}.jpg", contest_id: id}, current_user)
    json(conn, presigned_s3_url("#{now}", id, "contest"))
  end

  def presign(conn, %{"now" => now, "id" => id, "schema" => "photo"}) do
    current_user = Plug.current_resource(conn)
    contest = Contests.get_contest_by!(id: id)

    if Timex.before?(contest.expiry_at, Timex.now()) do
      {:error, :expired_contest}
    else
      Uploads.create_upload(
        %{type: 2, name: "#{now}_P_#{id}.jpg", contest_id: id},
        current_user
      )

      json(conn, presigned_s3_url("#{now}", id, "photo"))
    end
  end

  def presign(conn, %{"now" => now, "id" => id_param, "schema" => "user"}) do
    current_user = Plug.current_resource(conn)

    {id, _} =
      if is_binary(id_param) do
        Integer.parse(id_param)
      else
        {id_param, nil}
      end

    if id == current_user.id do
      Uploads.create_upload(%{type: 0, name: "#{now}_U_#{id}.jpg"}, current_user)
      json(conn, presigned_s3_url("#{now}", id, "user"))
    else
      {:error, :not_found}
    end
  end

  defp presigned_s3_url(prefix, id, schema) do
    bucket = "img.shuttertop.com"

    c =
      schema
      |> String.at(0)
      |> String.upcase()

    path = "#{prefix}_#{c}_#{id}.jpg"
    obj_s3 = Config.new(:s3, %{region: "eu-west-1"})

    {:ok, url} =
      S3.presigned_url(
        obj_s3,
        :put,
        bucket,
        path,
        query_params: [
          {"ACL", "authenticated-read"},
          {"contentType", "binary/octet-stream"},
          {"Content-Length", "1400000"}
        ]
      )

    %{presigned_url: url}
  end
end

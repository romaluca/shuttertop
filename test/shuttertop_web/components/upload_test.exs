defmodule ShuttertopWeb.Components.UploadTest do
  use ShuttertopWeb.ConnCase

  import Phoenix.LiveViewTest

  require Logger

  def inspect_html_safe(term) do
    term
    |> inspect()
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  def run(lv, func) do
    GenServer.call(lv.pid, {:run, func})
  end

  setup %{conn: conn} = config do
    entity_name = config[:entity]

    user = insert_user()

    conn =
      case config[:login] do
        :same ->
          guardian_login(user, :token)

        :another ->
          insert_user()
          |> guardian_login(:token)

        _ ->
          conn
      end

    entity =
      case entity_name do
        :user ->
          user

        _ ->
          insert_contest(user)
      end

    {:ok, user: user, entity_name: entity_name, entity: entity, conn: conn}
  end

  @tag entity: :photo, login: :same
  test "Photo upload success", %{entity: entity, conn: conn} do
    {:ok, lv, _} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, slug_path(entity)))

    assert lv
           |> element("#photo-upload-#{entity.id} input[type=\"file\"][name=\"upload\"]")
           |> has_element?()

    filename = "image_test.jpg"
    file = File.read!(Path.join([__DIR__, "../../support", filename]))

    upload =
      file_input(lv, "#photo-upload-#{entity.id}", :upload, [
        %{
          last_modified: 1_594_171_879_000,
          name: filename,
          content: file,
          size: 1_396_009,
          type: "image/jpeg"
        }
      ])

    assert {:ok, %{ref: _ref, config: %{chunk_size: _}}} = preflight_upload(upload)
  end

  @tag entity: :contest, login: :same
  test "Contest cover upload success", %{entity: entity, conn: conn} do
    {:ok, lv, _} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, slug_path(entity)))

    assert lv
           |> element("#contest-upload-#{entity.id} input[type=\"file\"][name=\"upload\"]")
           |> has_element?()

    filename = "image_test.jpg"
    file = File.read!(Path.join([__DIR__, "../../support", filename]))

    upload =
      file_input(lv, "#contest-upload-#{entity.id}", :upload, [
        %{
          last_modified: 1_594_171_879_000,
          name: filename,
          content: file,
          size: 1_396_009,
          type: "image/jpeg"
        }
      ])

    assert {:ok, %{ref: _ref, config: %{chunk_size: _}}} = preflight_upload(upload)
  end

  @tag entity: :user, login: :same
  test "User avatar upload success", %{entity: entity, conn: conn} do
    {:ok, lv, _} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.UserLive.Show, slug_path(entity)))

    assert lv
           |> element("#user-upload-#{entity.id} input[type=\"file\"][name=\"upload\"]")
           |> has_element?()

    filename = "image_test.jpg"
    file = File.read!(Path.join([__DIR__, "../../support", filename]))

    upload =
      file_input(lv, "#user-upload-#{entity.id}", :upload, [
        %{
          last_modified: 1_594_171_879_000,
          name: filename,
          content: file,
          size: 1_396_009,
          type: "image/jpeg"
        }
      ])

    assert {:ok, %{ref: _ref, config: %{chunk_size: _}}} = preflight_upload(upload)
  end

  @tag entity: :photo
  test "Photo and contest upload by not logged user error", %{entity: entity, conn: conn} do
    {:ok, lv, _} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, slug_path(entity)))

    assert !(lv
             |> element("#photo-upload-#{entity.id} input[type=\"file\"][name=\"upload\"]")
             |> has_element?())

    assert !(lv
             |> element("#contest-upload-#{entity.id} input[type=\"file\"][name=\"upload\"]")
             |> has_element?())
  end

  @tag entity: :user
  test "Avatar upload by not logged user error", %{entity: entity, conn: conn} do
    {:ok, lv, _} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.UserLive.Show, slug_path(entity)))

    assert !(lv
             |> element("#user-upload-#{entity.id} input[type=\"file\"][name=\"upload\"]")
             |> has_element?())
  end

  @tag entity: :user, login: :another
  test "Avatar upload by another user error", %{conn: conn, user: user} do
    {:ok, lv, _} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.UserLive.Show, slug_path(user)))

    assert !(lv
             |> element("#user-upload-#{user.id} input[type=\"file\"][name=\"upload\"]")
             |> has_element?())
  end

  @tag entity: :contest, login: :another
  test "Contest cover upload by another user error", %{conn: conn, entity: entity} do
    {:ok, lv, _} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, slug_path(entity)))

    assert !(lv
             |> element("#contest-upload-#{entity.id} input[type=\"file\"][name=\"upload\"]")
             |> has_element?())
  end

  @tag entity: :photo
  test "Photo upload in expired contest error", %{entity: entity, conn: conn} do
    entity =
      Ecto.Changeset.change(entity,
        expiry_at: Timex.to_datetime(Timex.shift(Timex.today(), days: -3))
      )
      |> Repo.update!()

    {:ok, lv, _} =
      live(conn, Routes.live_path(conn, ShuttertopWeb.ContestLive.Show, slug_path(entity)))

    assert !(lv
             |> element("#photo-upload-#{entity.id} input[type=\"file\"][name=\"upload\"]")
             |> has_element?())
  end
end

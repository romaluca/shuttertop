defmodule ShuttertopWeb.ContestLive.Form do
  use ShuttertopWeb, :live_page

  alias Shuttertop.{Contests, Uploads}
  alias Shuttertop.Contests.Contest

  require Logger

  on_mount ShuttertopWeb.RequiredLiveAuth

  def render(assigns) do
    ShuttertopWeb.ContestView.render("form.html", assigns)
  end

  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(%{
       body_id: "contestFormPage",
       app_version: Application.spec(:shuttertop, :vsn)
     })
     |> assigns_form(socket.assigns.live_action, params)}
  end

  def handle_event(
        "save",
        %{"contest" => contest_params} = params,
        %{assigns: %{contest: contest}} = socket
      ) do
    current_user = socket.assigns.current_user

    contest_params = param_date(contest_params, "expiry_at")
    changeset = Contest.changeset(contest, contest_params)

    upload =
      if is_nil(params["upload"]) do
        nil
      else
        Uploads.get_upload_by!(
          name: contest_params["upload"],
          user_id: current_user.id,
          type: 1,
          contest_id: contest.id
        )
      end

    socket =
      case Contests.update_contest(changeset) do
        {:ok, contest} ->
          if is_nil(params["upload"]) do
            socket
            |> put_flash(:info, "Contest updated successfully.")
            |> push_redirect(
              to: Routes.live_path(socket, ShuttertopWeb.ContestLive.Show, slug_path(contest))
            )
          else
            Uploads.delete_upload(upload)

            socket
            # |> render("contest.json", contest: contest)
          end

        {:error, changeset} ->
          if is_nil(params["upload"]) do
            assign(socket, %{
              contest: contest,
              changeset: changeset
            })
          else
            socket
            # |> render("changeset.json", changeset: changeset)
          end
      end

    {:noreply, socket}
  end

  def handle_event("save", %{"contest" => contest_params}, socket) do
    current_user = socket.assigns.current_user
    contest_params = param_date(contest_params, "expiry_at")

    socket =
      case Contests.create_contest(contest_params, current_user) do
        {:ok, contest} ->
          socket
          |> put_flash(:info, "Contest created successfully.")
          |> push_redirect(
            to: Routes.live_path(socket, ShuttertopWeb.ContestLive.Show, slug_path(contest))
          )

        {:error, :contest, changeset, _} ->
          assign(socket, %{changeset: changeset})
      end

    {:noreply, socket}
  end

  def handle_event(
        "validate",
        %{"contest" => contest_params},
        %{assigns: %{live_action: :new}} = socket
      ) do
    contest_params = param_date(contest_params, "expiry_at")

    changeset =
      socket.assigns.current_user
      |> Ecto.build_assoc(:contests, start_at: DateTime.truncate(DateTime.utc_now(), :second))
      |> Contest.changeset(contest_params)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event(
        "validate",
        %{"contest" => _contest_params},
        %{assigns: %{live_action: :edit}} = socket
      ) do
    {:noreply, socket}
  end

  defp assigns_form(socket, :new, params) do
    expiry_at = Timex.shift(Timex.today(), days: 14)

    name =
      case params["contest_id"] do
        nil ->
          nil

        contest_id ->
          contest = Contests.get_contest_by!(%{id: contest_id})
          contest.name
      end

    changeset =
      Contest.changeset(%Contest{
        expiry_days: 2,
        expiry_at: expiry_at,
        name: name,
        contest_id: params["contest_id"]
      })

    socket = assign(socket, %{changeset: changeset})

    assign(socket, %{
      title: page_title(:new, socket.assigns),
      page_title: page_title(:new, socket.assigns),
      title_bar: page_title(:new, socket.assigns)
    })
  end

  defp assigns_form(socket, :edit, %{"id" => id} = _params) do
    current_user = socket.assigns.current_user

    contest =
      if is_admin(current_user) do
        Contests.get_contest_by!(id: id)
      else
        Contests.get_contest_by!(id: id, user_id: current_user.id)
      end

    new_date = DateTime.to_date(contest.expiry_at)

    changeset =
      Contest.changeset(contest)
      |> Ecto.Changeset.change(%{expiry_at: new_date})

    assign(socket, %{
      contest: contest,
      changeset: changeset,
      title_bar: gettext("Modifica contest"),
      title: gettext("Modifica %{name}", name: contest.name)
    })
  end

  defp page_title(:new, assigns) do
    if is_nil(assigns.changeset.data.contest_id) do
      gettext("Nuovo contest")
    else
      "#{assigns.changeset.data.name} · #{gettext("Nuova edizione")}"
    end
  end
end

defmodule ShuttertopWeb.UserLive.Edit do
  use ShuttertopWeb, :live_page

  require Logger

  alias Shuttertop.Accounts
  alias Shuttertop.Accounts.{User}
  alias Shuttertop.Repo

  def render(assigns) do
    ShuttertopWeb.UserView.render("edit.html", assigns)
  end

  on_mount ShuttertopWeb.InitLiveAssigns

  def mount(_params, _session, socket) do
    user = Accounts.get_user_by(id: socket.assigns.current_user.id)
    changeset = User.changeset(user)

    {:ok,
     assign(socket,
       user: user,
       changeset: changeset,
       page_title: gettext("Modifica utente"),
       title_bar: gettext("Modifica utente")
     )}
  end

  def handle_event("save", %{"user" => user_params} = _params, socket) do
    changeset = User.changeset(socket.assigns.current_user, user_params)

    case Repo.update(changeset) do
      {:ok, user} ->
        Gettext.put_locale(ShuttertopWeb.Gettext, user.language)

        {:noreply,
         socket
         |> put_flash(:info, Gettext.gettext(ShuttertopWeb.Gettext, "You updated successfully."))
         |> redirect(to: Routes.live_path(socket, ShuttertopWeb.UserLive.Show, slug_path(user)))}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end

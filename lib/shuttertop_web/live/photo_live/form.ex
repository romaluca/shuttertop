defmodule ShuttertopWeb.PhotoLive.Form do
  use ShuttertopWeb, :live_page

  alias Shuttertop.{Accounts, Photos}
  alias Shuttertop.Photos.Photo

  require Logger

  def render(assigns) do
    ShuttertopWeb.PhotoView.render("photo_form.html", assigns)
  end

  def mount(_params, %{"photo_id" => photo_id, "user_id" => user_id}, socket) do
    current_user = Accounts.get_user(user_id)
    photo = Photos.get_photo_by!(id: photo_id, user_id: current_user.id)
    changeset = Photo.changeset(photo)

    {:ok,
     socket
     |> assign(%{
       changeset: changeset,
       photo_id: photo_id,
       user_id: user_id
     }), layout: false}
  end

  def handle_event("save", %{"photo" => photo_params} = _args, socket) do
    current_user = Accounts.get_user(socket.assigns.user_id)
    photo = Photos.get_photo_by!(id: socket.assigns.photo_id, user_id: current_user.id)

    case Photos.update_photo(photo, photo_params) do
      {:ok, _photo} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Photo updated successfully."))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end

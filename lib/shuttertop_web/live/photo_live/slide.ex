defmodule ShuttertopWeb.PhotoLive.Slide do
  use ShuttertopWeb, :live_page

  require Logger

  alias Shuttertop.{Photos, Posts}
  alias Shuttertop.Photos.Photo

  @page_size 30

  def render(assigns) do
    ~H"""
    <% entity = if(@type == :contest, do: @contest, else: @user) %>
    <div class="photo_page" id={"photoSlide-#{@photo.id}"} data-id={@photo.id}
        phx-hook="SlideUpdate">
        <div class="row photo-row">
            <div class="photo-container col-offset text-xs-center">
                <div id="gallery">
                    <div id="gallery-content" phx-update="replace" data-entries={@total_entries}>
                        <%= for i <- @gallery do %>
                            <%= live_patch to: "/#{@entity_name}/#{slug_path(entity)}/photos/#{@view}/#{i.id}",
                                id: "gallery-photo-#{i.id}",
                                class: "gallery-photo" do %><%= img_tag upload_url(i, :thumb), loading: "lazy" %><% end %>
                        <% end %>
                    </div>
                    <button id="prev-page" class="page-btn"><i class="icons prev"></i></button>
                    <button id="next-page" class="page-btn"><i class="icons next"></i></button>
                    <button id="more-page" phx-click="more"></button>
                </div>
                <div class="slidernav" id="slidernav" phx-window-keyup="slider_key">
            <button class="prev" phx-click="prev"><i class="icons prev"></i></button>
            <button class="next" phx-click="next"><i class="icons next"></i></button>
                    <div class="loading-ico"><i class="icons loading" ></i></div>
          </div>
          <div class="photo-current">
                    <%= img_tag upload_url(@photo, :normal), loading: "lazy", class: "photo-user" %>
                </div>
            </div>
            <div class="col-fixed col-md-12" id="slideSidebarContainer">
                <%= ShuttertopWeb.PhotoView.render "sidebar.html", assigns %>
            </div>
        </div>
    </div>
    """
  end

  def mount(%{"entity" => entity_name, "photo_id" => photo_id, "view" => view}, _, socket)
      when view in ["news", "top", "my", "in_progress"] and entity_name in ["contests", "users"] do
    current_user = socket.assigns.current_user

    type =
      case entity_name do
        "contests" -> :contest
        "users" -> :user
      end

    {:ok,
     socket
     |> assign(%{
       type: type,
       view: String.to_existing_atom(view),
       limit: @page_size,
       entity_name: entity_name,
       photo_id: photo_id,
       current_user: current_user,
       body_id: "photoPage",
       disable_slide_key: false
     })
     |> fetch()}
  end

  def handle_params(%{"photo_id" => photo_id}, _, socket) do
    {:noreply, assign(socket, photo_id: photo_id) |> fetch()}
  end

  def handle_event(
        "slider_key",
        %{"key" => "ArrowRight"},
        %{
          assigns: %{disable_slide_key: false}
        } = socket
      ) do
    handle_event("next", %{}, socket)
  end

  def handle_event("slider_key", %{"key" => "ArrowRight"}, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "slider_key",
        %{"key" => "ArrowLeft"},
        %{
          assigns: %{disable_slide_key: false}
        } = socket
      ) do
    handle_event("prev", %{}, socket)
  end

  def handle_event("slider_key", %{"key" => "ArrowLeft"}, socket) do
    {:noreply, socket}
  end

  def handle_event("slider_key", _, socket) do
    {:noreply, socket}
  end

  def handle_event(
        "next",
        _,
        %{
          assigns:
            %{
              type: type,
              contest: contest,
              user: user,
              photo: photo,
              entity_name: entity_name,
              view: view,
              current_user: current_user
            } = _assigns
        } = socket
      ) do
    entity = if(type == :contest, do: contest, else: user)

    case Photos.get_photo_slide(entity, view, photo.id, 1, current_user) do
      nil ->
        {:noreply, socket}

      photo_id ->
        {:noreply,
         push_patch(socket,
           to:
             Routes.live_path(
               socket,
               ShuttertopWeb.PhotoLive.Slide,
               entity_name,
               slug_path(entity),
               view,
               photo_id
             )
         )}
    end
  end

  def handle_event(
        "prev",
        _,
        %{
          assigns: %{
            type: type,
            contest: contest,
            user: user,
            photo: photo,
            entity_name: entity_name,
            view: view,
            current_user: current_user
          }
        } = socket
      ) do
    entity = if(type == :contest, do: contest, else: user)

    case Photos.get_photo_slide(entity, view, photo.id, -1, current_user) do
      nil ->
        {:noreply, socket}

      photo_id ->
        {:noreply,
         push_patch(socket,
           to:
             Routes.live_path(
               socket,
               ShuttertopWeb.PhotoLive.Slide,
               entity_name,
               slug_path(entity),
               view,
               photo_id
             )
         )}
    end
  end

  def handle_event(
        "more",
        _,
        %{
          assigns: %{
            type: type,
            photo: photo,
            limit: limit,
            total_entries: total_entries,
            view: view,
            current_user: current_user
          }
        } = socket
      ) do
    if total_entries <= limit do
      {:noreply, socket}
    else
      limit = limit + @page_size

      gallery =
        view
        |> get_params(photo, type, current_user, limit)
        |> Photos.get_photos(current_user)

      {:noreply, assign(socket, gallery: gallery, limit: limit)}
    end
  end

  def handle_event("comment-focus", _, socket) do
    {:noreply, assign(socket, disable_slide_key: true)}
  end

  def handle_event("comment-blur", _, socket) do
    {:noreply, assign(socket, disable_slide_key: false)}
  end

  def handle_info({_, :created, comment}, socket) do
    send_update(ShuttertopWeb.Components.Chat,
      id: "photoComment-#{socket.assigns.photo.id}",
      new_comment: comment
    )

    {:noreply, socket}
  end

  defp fetch(
         %{
           assigns:
             %{
               photo_id: photo_id,
               current_user: current_user,
               type: type,
               entity_name: entity_name,
               view: view
             } = assigns
         } = socket
       ) do
    photo = Photos.get_photo_by!([id: photo_id], current_user)
    topic = if photo.topic_id, do: Posts.get_topic(photo.topic_id), else: nil
    subscribe_topic(photo, socket)
    changeset = Photo.changeset(photo)
    params = get_params(view, photo, type, current_user)

    {gallery, total_entries} =
      if is_nil(assigns[:gallery]) do
        g = Photos.get_photos(params, current_user)
        {g.entries, g.total_entries}
      else
        {assigns[:gallery], assigns[:total_entries]}
      end

    entity = if type == :contest, do: photo.contest, else: photo.user

    desc =
      cond do
        photo.contest.winner_id == photo.id ->
          gettext("La foto vincitrice del contest fotografico")

        photo.contest.is_expired ->
          gettext("Commenta la foto")

        true ->
          gettext("Vota e commenta la foto!")
      end

    assign(socket,
      gallery: gallery,
      total_entries: total_entries,
      photo: photo,
      photo_id: photo.id,
      topic: topic,
      user: photo.user,
      page_title: "#{photo.user.name} at #{photo.contest.name}",
      title_bar: entity.name,
      meta: [
        title: "#{photo.user.name} > #{photo.contest.name}",
        description: Gettext.gettext(ShuttertopWeb.Gettext, desc),
        image: "/#{photo.upload}",
        image_width: photo.width,
        image_height: photo.height,
        url: "/#{entity_name}/#{slug_path(entity)}/photos/#{view}/#{photo.id}"
      ],
      subtitle_bar: get_photo_subtitle(type, view),
      contest: photo.contest,
      changeset: changeset
    )
  end

  defp subscribe_topic(%Photo{} = photo, %{assigns: %{photo: %Photo{id: id}}} = socket) do
    if photo.id != id do
      Posts.get_subscribe_name("photo", id, socket.assigns.current_user)
      |> Posts.unsubscribe_topic()

      Posts.get_subscribe_name("photo", photo.id, socket.assigns.current_user)
      |> Posts.subscribe_topic()
    end
  end

  defp subscribe_topic(%Photo{} = photo, socket) do
    Posts.get_subscribe_name("photo", photo.id, socket.assigns.current_user)
    |> Posts.subscribe_topic()
  end

  defp subscribe_topic(_, _), do: nil

  defp get_params(view, photo, type, current_user, limit \\ 0) do
    params =
      case view do
        :in_progress -> %{order: :news, not_expired: true}
        :my -> %{order: :news, user_id: current_user.id}
        _ -> %{order: view}
      end

    params =
      if type == :contest do
        Map.put(params, :contest_id, photo.contest_id)
      else
        Map.put(params, :user_id, photo.user_id)
      end

    if limit > 0, do: Map.put(params, :limit, limit), else: params
  end

  def get_photo_subtitle(type, order) do
    desc =
      case {type, order} do
        {:contest, :news} -> gettext("Le foto in ordine di inserimento")
        {:contest, :top} -> gettext("La classifica")
        {:user, :news} -> gettext("Le ultime foto inserite")
        {:user, :top} -> gettext("Le foto con più top")
        {:user, :in_progress} -> gettext("Le sue sfide in corso")
        {_, _} -> ""
      end

    Gettext.gettext(ShuttertopWeb.Gettext, desc)
  end
end

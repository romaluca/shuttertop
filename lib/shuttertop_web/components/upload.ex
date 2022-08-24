defmodule ShuttertopWeb.Components.Upload do
  use ShuttertopWeb, :live_component

  require Logger

  alias S3Upload
  alias ShuttertopWeb.Components.Modal

  def update(%{entity_id: id, entity: entity, current_user: current_user} = params, socket) do
    {:ok,
     socket
     |> assign(%{
       uploaded_files: [],
       id: id,
       icon: params[:icon],
       label: params[:label],
       form_class: params[:form_class],
       label_class: params[:label_class],
       changeset: params[:changeset],
       current_user: current_user,
       entity: entity
     })
     |> allow_upload(:upload,
       accept: ~w(.jpeg .jpg),
       max_entries: 1,
       auto_upload: true,
       ref: "miao",
       external: &presign_entry/2,
       progress: &handle_progress/3
     )}
  end

  def render(assigns) do
    is_uploading = is_uploading(assigns)
    entity = Atom.to_string(assigns[:entity])

    ~H"""
    <div>
    <.form let={f} for={@changeset} class={"clickable upload-btn#{if is_uploading, do: " in-progress"} #{assigns[:form_class]}"} phx-target={@myself} phx-submit="save" phx-change="validate" id={"#{entity}-upload-#{@id}"}>

      <%= unless is_uploading do %>
      <label for={if assigns.current_user, do: @uploads.upload.ref} class={"clickable #{assigns[:label_class]}"} phx-click="label-click" phx-target={@myself}>
        <%= if assigns[:icon] do %>
          <i class={"icons #{assigns[:icon]}"} aria-hidden="true"></i>
          <span><%= Gettext.gettext(ShuttertopWeb.Gettext, assigns[:label]) %></span>
        <% else %>
          <%= Gettext.gettext(ShuttertopWeb.Gettext, assigns[:label])  %>
        <% end %>
      </label>
      <% end %>
      <%= if assigns.current_user, do: live_file_input(@uploads.upload, class: "input-file") %>
      <div class="js-signed-upload-status">
          <%= for entry <- @uploads.upload.entries do %>
            <%= entry.progress %>%
          <% end %>
      </div>
      <%= hidden_input f, :upload %>
      <%= if assigns.entity == :photo, do: hidden_input(f, :meta) %>
    </.form>
    </div>
    """
  end

  defp is_uploading(assigns) do
    !(is_nil(assigns.uploads) || is_nil(assigns.uploads.upload) ||
        is_nil(assigns.uploads.upload.entries) || assigns.uploads.upload.entries == [])
  end

  def handle_progress(:upload, entry, socket) do
    if entry.done? do
      uploaded_file =
        consume_uploaded_entry(socket, entry, fn %{} = meta ->
          meta
        end)

      {:noreply, update_changeset(socket, :upload, uploaded_file.key)}
    else
      {:noreply, socket}
    end
  end

  def update_changeset(%{assigns: %{changeset: changeset}} = socket, key, value) do
    assign(socket, :changeset, Ecto.Changeset.put_change(changeset, key, value))
  end

  def handle_event("label-click", _params, socket) do
    unless socket.assigns.current_user do
      send_update(Modal, id: "modalDialog", type: "login")
    end

    {:noreply, socket}
  end

  def handle_event("validate", %{"photo" => photo_params}, socket) do
    changeset = Ecto.Changeset.cast(socket.assigns.changeset, photo_params, [:meta, :upload])
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("validate", _, socket), do: {:noreply, socket}

  def handle_event("save", %{"photo" => photo_params}, socket) do
    photo_params =
      if photo_params["meta"] && photo_params["meta"] != "" do
        meta = Jason.decode!(photo_params["meta"])
        %{photo_params | "meta" => meta}
      else
        photo_params
      end

    send(self(), {:uploaded, socket.assigns.entity, photo_params})
    {:noreply, socket}
  end

  def handle_event("save", params, socket) do
    entity = Atom.to_string(socket.assigns.entity)
    send(self(), {:uploaded, socket.assigns.entity, params[entity]})
    {:noreply, socket}
  end

  @bucket "img.shuttertop.com"
  defp s3_host() do
    region = Application.get_env(:ex_aws, :region)
    # "//#{@bucket}.s3.amazonaws.com"
    "//s3.#{region}.amazonaws.com/#{@bucket}"
  end

  defp s3_entry(socket, entry) do
    c =
      socket.assigns.entity
      |> Atom.to_string()
      |> String.at(0)
      |> String.upcase()

    c = if Application.get_env(:shuttertop, :environment) == :dev, do: "DEV_#{c}", else: c

    if socket.assigns.entity == :photo do
      "#{c}_#{socket.assigns.id}_U_#{socket.assigns.current_user.id}_#{entry.uuid}.jpg"
    else
      "#{c}_#{socket.assigns.id}_#{entry.uuid}.jpg"
    end
  end

  def presign_entry(entry, socket) do
    key = s3_entry(socket, entry)

    config = %{
      access_key_id: Application.get_env(:ex_aws, :access_key_id),
      secret_access_key: Application.get_env(:ex_aws, :secret_access_key),
      region: Application.get_env(:ex_aws, :region)
    }

    {:ok, fields} =
      S3Upload.sign_form_upload(config, @bucket,
        key: key,
        content_type: entry.client_type,
        max_file_size: 1_400_000,
        expires_in: :timer.hours(1)
      )

    meta = %{uploader: "S3", key: key, url: s3_host(), fields: fields}
    {:ok, meta, socket}
  end
end

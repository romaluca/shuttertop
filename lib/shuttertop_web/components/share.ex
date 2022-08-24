defmodule ShuttertopWeb.Components.Share do
  use ShuttertopWeb, :live_component
  require Logger

  def update(%{url: url} = _params, socket) do
    {:ok, assign(socket, url: url)}
  end

  def render(assigns) do
    ~H"""
    <div class="modal-share">
        <button type="button" phx-click="hide-modal" phx-target="#modalDialog" class="btn-close" aria-label="Close" id="shareHideBtn"></button>
        <h2 class="modal-title" data-photos={ gettext "Condividi la foto" }>
        <%= gettext "Condividi il contest" %>
        </h2>
        <p>
            <div class="container share-buttons">
                <div class="row">
                    <div class="col-6 facebook element clickable" onclick={"window.sharePopup(event, 'facebook', '#{@url}')"}>
                        <div><i class="icon-facebook"></i></div>
                        <span>Facebook</span>
                    </div>
                    <div class="col-6 twitter element clickable" onclick={"window.sharePopup(event, 'twitter', '#{@url}')"}>
                        <div><i class="icon-twitter"></i></div>
                        <span>Twitter</span>
                    </div>
                    <div class="col-6 whatsapp element clickable" onclick={"window.sharePopup(event, 'whatsapp', '#{@url}')"}>
                        <div><i class="icon-whatsapp"></i></div>
                        <span>Whatsapp</span>
                    </div>
                    <div class="col-6 mail element clickable" onclick={"window.sharePopup(event, 'mail', '#{@url}')"}>
                        <div><i class="icons mail"></i></div>
                        <span><%= gettext "mail" %></span>
                    </div>
                </div>
            </div>
        </p>
    </div>
    """
  end
end

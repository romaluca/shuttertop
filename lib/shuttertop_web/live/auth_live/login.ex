defmodule ShuttertopWeb.AuthLive.Login do
  use ShuttertopWeb, :live_component

  require Logger

  alias Shuttertop.Accounts.User
  alias Shuttertop.Repo

  def render(assigns) do
    ~H"""
      <div class="container login-container" id="loginContainer">
      <% conn = assigns[:conn] || assigns[:socket] %>
      <div class="row">
        <div class="col m-auto pt-5" style="max-width:500px">
        <%= form_tag Routes.auth_path(conn, :callback, "identity"), method: "post", class: "login mx-auto", novalidate: true do %>
        <div class="card">
          <div class="card-header">
            <h1><%= gettext "accedi con" %></h1>
          </div>
          <div class="card-body">

              <div class="auth-links text-center">
                  <div class="">
                    <div class="row">
                      <div class="col">
                      <%= if not Enum.member?(@current_auths, "facebook") do %>
                        <a href={Routes.auth_path(conn, :login, "facebook")} class="facebook-btn btn btn-block">
                          <i class="icon-facebook" aria-hidden="true"></i>
                        </a>
                      <% end %>
                      </div>
                      <div class="col">
                      <%= if not Enum.member?(@current_auths, "google") do %>
                        <a href={Routes.auth_path(conn, :login, "google")} class="google-btn btn btn-block">
                          <i class="icon-google" aria-hidden="true"></i>
                        </a>
                      <% end %>
                      </div>
                      <div class="col">
                        <a href="#" class="apple-btn btn btn-block" id="sign-in-with-apple-button"
                            onclick="window.loadApple(event)">
                          <i class="icon-apple" aria-hidden="true"></i>
                        </a>
                      </div>
                    </div>
                  </div>
                  <div class="or-div"><span><%= gettext "oppure con" %></span></div>
              </div>
              <%= if !is_nil(@error) do %>
                <div class="error help-block pb-2 text-center"><%= get_auth_error(@error) %></div>
              <% end %>
              <div class="form-group">
                <label for="email"><%= gettext "Email address" %>:</label>
                <input type="email" class="form-control validate" name="email" pattern="^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$" >
              </div>
              <div class="form-group pt-3">
                <label for="password"><%= gettext "Password" %>:</label>
                <input type='password' class="form-control" name="password" autocomplete="off">
              </div>
              <input type="hidden" name="redirect" id="redirectUrl">
                <%= live_redirect to: Routes.live_path(conn, ShuttertopWeb.AuthLive.PasswordRecovery, content: 1), class: "form-link text-end d-block" do %>
                  <%= gettext "Password dimenticata?" %>
                <% end %>
                <button class="btn btn-primary btn-block btn-login mt-3"><%= gettext "Accedi" %></button>
          </div>
        </div>
        <% end %>
      </div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
     assign(socket, %{
       current_user: assigns[:current_user],
       current_auths: auths(assigns[:current_user]),
       error: assigns[:error]
     })}
  end

  defp auths(nil), do: []

  defp auths(%User{} = user) do
    user
    |> Ecto.assoc(:authorizations)
    |> Repo.all()
    |> Enum.map(& &1.provider)
  end

  @spec get_auth_error(atom | any) :: binary()
  defp get_auth_error(:password_confirmation_does_not_match) do
    gettext("Mail e/o password errati")
  end

  defp get_auth_error(:password_does_not_match) do
    gettext("Mail e/o password errati")
  end

  defp get_auth_error(text), do: text
end

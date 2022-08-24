defmodule ShuttertopWeb.UserLive.New do
  use ShuttertopWeb, :live_page

  require Logger

  alias Shuttertop.Accounts
  alias Shuttertop.Accounts.{Authorization, User}
  alias Shuttertop.Jobs.UserMailerJob
  alias Shuttertop.Repo

  def render(%{created: true} = assigns) do
    ~H"""
    <div class="container">
      <div class="row">
        <div class="col-12 col-lg-8 mx-auto page-content">
          <div class="card">
            <div class="card-header">
              <h1><%= gettext "Un ultimo sforzo" %></h1>
            </div>
            <div class="card-body p-lr-075">
                  <%= gettext("Ciao %{name}! ti abbiamo inviato una mail a %{email} con uno stupido link da cliccare.", name: @user.name, email: @user.email) %>
                  <br /><br />
                  <%= gettext("Fallo e sarai a bordo!") %>
              </div>
          </div>

        </div>
        </div>
    </div>
    """
  end

  def render(assigns) do
    ShuttertopWeb.UserView.render("new.html", assigns)
  end

  def mount(_params, _session, socket) do
    changeset = User.changeset(%User{authorizations: [%Authorization{}]})

    {:ok,
     socket
     |> assign(changeset: changeset, recaptcha: true, page_title: gettext("Registrazione utente"))}
  end

  def handle_event("save", %{"user" => user_params} = params, socket) do
    robot_error =
      case Recaptcha.verify(params["g-recaptcha-response"]) do
        {:ok, _response} ->
          Application.get_env(:shuttertop, :environment) == :prod

        {:error, errors} ->
          Logger.warn("error #{inspect(errors)} #{inspect(params)}")

          true
      end

    locale = Gettext.get_locale(ShuttertopWeb.Gettext)
    user_params = Map.put(user_params, "language", locale)

    case Accounts.create_user(user_params, robot_error) do
      {:ok, user} ->
        {:ok, now} =
          Timex.now()
          |> Timex.format("%Y%m%d%H%M%S", :strftime)

        token = Bcrypt.hash_pwd_salt("#{now}#{user.email}")

        Accounts.get_authorization_by(provider: "identity", uid: user.email)
        |> Ecto.Changeset.cast(%{recovery_token: token}, [:recovery_token])
        |> Repo.update!()

        UserMailerJob.enqueue_registration_confirm(user)
        {:noreply, assign(socket, created: true, user: user)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset, recaptcha: true)}
    end
  end
end

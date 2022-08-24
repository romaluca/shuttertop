defmodule ShuttertopWeb.Api.AuthView do
  use ShuttertopWeb, :view

  def render("login.json", %{user: user, jwt: jwt, exp: exp}) do
    %{
      user: render(ShuttertopWeb.Api.UserView, "user_me.json", user: user),
      notify_count: user.notify_count,
      notify_message_count: user.notify_message_count,
      notifies_enabled: user.notifies_enabled,
      notify_contest_created: user.notify_contest_created,
      language: user.language,
      jwt: jwt,
      exp: exp
    }
  end

  def render("recovery.json", %{user: user, token: token, email: email}) do
    %{
      user: render(ShuttertopWeb.Api.UserView, "recovery.json", user: user),
      notify_count: user.notify_count,
      notify_message_count: user.notify_message_count,
      notifies_enabled: user.notifies_enabled,
      notify_contest_created: user.notify_contest_created,
      token: token,
      email: email
    }
  end

  def render("error.json", %{error: error}) do
    %{error: error}
  end
end

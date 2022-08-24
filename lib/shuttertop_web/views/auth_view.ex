defmodule ShuttertopWeb.AuthView do
  use ShuttertopWeb, :view

  # def render("credentials.json", %{user: user, jwt: jwt}) do
  #   %{user: user, jwt: jwt}
  # end
  @spec subtitle_bar(any, any) :: nil
  def subtitle_bar(_, _), do: nil
end

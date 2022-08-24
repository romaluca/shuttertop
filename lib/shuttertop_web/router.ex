defmodule ShuttertopWeb.Router do
  use ShuttertopWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug :fetch_live_flash
    plug :put_root_layout, {ShuttertopWeb.LayoutView, :root}
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(Shuttertop.Guardian.AuthPipeline.Browser)
    plug(Shuttertop.Locale)
  end

  pipeline :browser_admin do
    plug Guardian.Plug.EnsureAuthenticated #, handler: ShuttertopWeb.GuardianErrorHandler
    plug(ShuttertopWeb.Plug.CheckAdmin)
  end

  pipeline :api_auth do
    plug(:accepts, ["json"])
    plug(Shuttertop.Guardian.AuthPipeline.JSON)
    plug(JaSerializer.Deserializer)
  end

  pipeline :api_auth_key do
    plug Shuttertop.APIKey
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug Shuttertop.APIKey
    plug(JaSerializer.Deserializer)
  end

  scope "/", ShuttertopWeb do
    pipe_through([:browser])
    live "/", ActivityLive.Index
    # get("/credentials", AuthController, :credentials)
    live "/notifies", ActivityLive.Notifies
    live "/topics/:id", CommentLive.Messages
    live "/topics", CommentLive.Messages
    live "/contact", PageLive.Contact
    live "/:entity/upload/:id", ComponentsLive.Upload
    live "/:entity/:id/photos/:view/:photo_id", PhotoLive.Slide
    live "/leaders", UserLive.Index
    live "/users/edit", UserLive.Edit
    live "/users/:id", UserLive.Show
    live "/contests", ContestLive.Index
    live "/contests/new", ContestLive.Form, :new
    live "/contests/edit", ContestLive.Form, :edit
    live "/contests/:id", ContestLive.Show
    live "/constests/:id/:section", ContestLive.Show
    live "/contests/category/:category_id", ContestLive.Index
    delete("/logout", AuthController, :logout)
  end

  scope "/", ShuttertopWeb do
    pipe_through([:browser])
    live "/another_life", AuthLive.Recovery
    live "/auth/identity", AuthLive.Index
    get("/registration_confirm", AuthController, :registration_confirm)
    live "/signup", UserLive.New
    live "/terms", PageLive.Index, :terms_en
    live "/terms/:lang", PageLive.Index, :terms
    live "/about", PageLive.Index, :about
    live "/privacy", PageLive.Index, :privacy_en
    live "/privacy/:lang", PageLive.Index, :privacy
  end

  scope "/auth", ShuttertopWeb do
    # Use the default browser stack
    pipe_through([:browser])

    live "/password_recovery", AuthLive.PasswordRecovery
    get("/:identity", AuthController, :login)
    get("/:identity/callback", AuthController, :callback)
    post("/:identity/callback", AuthController, :callback)
    get("/:identity/delete", AuthController, :delete)
  end

  scope "/admin", ShuttertopWeb do
    pipe_through([:browser, :browser_admin])
    live "/", AdminLive.Show
  end

  scope "/api/auth", ShuttertopWeb.Api, as: :api do
    pipe_through [:api, :api_auth_key]

    post("/social/:provider/:token", AuthController, :social)
    post("/newuser", UserController, :create)
    post("/password_recovery", AuthController, :password_recovery)
  end

  scope "/api", ShuttertopWeb.Api, as: :api do
    pipe_through [:api_auth, :api_auth_key]

    get("/current_session", AuthController, :current_session)
    resources("/users", UserController, except: [:delete, :new, :create])
    resources("/invitations", InvitationController, only: [:create])
    post("/friends", UserController, :index, as: :friends)
    get("/contests/topweek", ContestController, :top_week)
    resources("/contests", ContestController)
    resources("/activities", ActivityController, only: [:index, :delete, :create])
    resources("/comments", CommentController, only: [:index, :create])
    get("/topics", CommentController, :get_topics)
    get("/notifies", ActivityController, :notifies)
    delete("/logout", AuthController, :logout)
    resources("/photos", PhotoController)
    post("/photos/report", PhotoController, :report)
    put("/presign_upload/:schema/:id", UploadController, :presign)
    post("/users/block", UserController, :block)
    delete("/users/block/:id", UserController, :unblock)
  end

  scope "/api/auth", ShuttertopWeb.Api, as: :api do
    pipe_through [:api_auth, :api_auth_key]

    post("/change_password", AuthController, :change_password)
  end

  scope "/api", ShuttertopWeb.Api, as: :api do
    pipe_through [:api_auth]
    resources("/devices", DeviceController, only: [:create, :delete])
    post("/devices/test_notify", DeviceController, :test_notify)
    get("/auth/:identity/callback", AuthController, :callback)
    post("/auth/:identity/callback", AuthController, :callback)
  end

  scope "/api", ShuttertopWeb.Api, as: :api do
    pipe_through [:api, :api_auth_key]
    get("/devices/get_info", DeviceController, :get_info)
    get("/contests/share_params/:id", ContestController, :share_params)
    post("/registration_confirm", AuthController, :registration_confirm)
    post("/another_life", AuthController, :recovery)
    post("/another_life_confirm", AuthController, :recovery)
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  import Phoenix.LiveDashboard.Router

  scope "/" do
    if Mix.env() in [:dev, :test] do
      pipe_through :browser
    else
      pipe_through([:browser, :browser_admin])
    end

    live_dashboard "/dashboard", metrics: ShuttertopWeb.Telemetry, ecto_repos: [Shuttertop.Repo]
  end
end

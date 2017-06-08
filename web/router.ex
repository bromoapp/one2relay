defmodule One2relay.Router do
  use One2relay.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", One2relay do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/anchor", AnchorController, :index
    get "/audience", AudienceController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", One2relay do
  #   pipe_through :api
  # end
end

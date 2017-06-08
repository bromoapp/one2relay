defmodule One2relay.PageController do
  use One2relay.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end

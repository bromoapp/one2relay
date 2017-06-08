defmodule One2relay.AnchorController do
    use One2relay.Web, :controller
    
    def index(conn, _args) do
        render conn, "index.html"
    end
end
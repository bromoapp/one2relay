# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :one2relay,
  ecto_repos: [One2relay.Repo]

# Configures the endpoint
config :one2relay, One2relay.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "yUG+wTwR7B7OS1UXoiMOn2YqjU2nzOzr5IblDB5flAQg+fmcjeEJIoXpOekVe0tr",
  render_errors: [view: One2relay.ErrorView, accepts: ~w(html json)],
  pubsub: [name: One2relay.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

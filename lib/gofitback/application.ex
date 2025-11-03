defmodule Gofitback.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GofitbackWeb.Telemetry,
      Gofitback.Repo,
      {DNSCluster, query: Application.get_env(:gofitback, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Gofitback.PubSub},
      # Start a worker by calling: Gofitback.Worker.start_link(arg)
      # {Gofitback.Worker, arg},
      # Start to serve requests, typically the last entry
      GofitbackWeb.Endpoint,
      {Absinthe.Subscription, GofitbackWeb.Endpoint},
      AshGraphql.Subscription.Batcher
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gofitback.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GofitbackWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

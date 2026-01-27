defmodule OrquestraX.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OrquestraX.Repo,
      {DNSCluster, query: Application.get_env(:orquestra_x, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: OrquestraX.PubSub},
      {Registry, keys: :unique, name: OrquestraX.Registry},
      {OrquestraX.Engine.WorkflowSupervisor, []},
      {Cluster.Supervisor, [Application.get_env(:libcluster, :topologies) || [], [name: OrquestraX.ClusterSupervisor]]}
      # Start a worker by calling: OrquestraX.Worker.start_link(arg)
      # {OrquestraX.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: OrquestraX.Supervisor)
  end
end

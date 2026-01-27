defmodule OrquestraXWorker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Cluster.Supervisor, [Application.get_env(:libcluster, :topologies) || [], [name: OrquestraXWorker.ClusterSupervisor]]}
      # Starts a worker by calling: OrquestraXWorker.Worker.start_link(arg)
      # {OrquestraXWorker.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OrquestraXWorker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

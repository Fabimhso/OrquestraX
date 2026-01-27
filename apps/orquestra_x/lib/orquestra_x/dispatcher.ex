defmodule OrquestraX.Dispatcher do
  require Logger

  def dispatch(orchestrator_pid, step, context) do
    # Simple strategy: Random available worker node
    # In production, use consistent hashing or specific tagging
    nodes = Node.list() ++ [Node.self()] # Include self for local dev if configured

    case Enum.random(nodes) do
      node when not is_nil(node) ->
        Logger.info("Dispatching step #{step["id"]} to node #{node}")
        # Async cast to worker
        # We pass the orchestrator PID so the worker can report back
        :rpc.cast(node, OrquestraXWorker.JobRunner, :run_async, [orchestrator_pid, step, context])
        {:ok, node}
      _ ->
        {:error, :no_workers_available}
    end
  end
end

defmodule OrquestraXWorker.JobRunner do
  require Logger

  def run_async(orchestrator_pid, step, context) do
    Task.start(fn ->
      run(orchestrator_pid, step, context)
    end)
  end

  def run(orchestrator_pid, step, _context) do
    Logger.info("Executing step #{step["id"]} on #{inspect(Node.self())}")

    # Simulate work
    Process.sleep(2000)

    result = %{"status" => "success", "step_id" => step["id"], "worker" => inspect(Node.self())}

    # Report back to Orchestrator (Core)
    GenServer.cast(orchestrator_pid, {:step_completed, result})

    Logger.info("Step finished. Result sent back to orchestrator.")
  end
end

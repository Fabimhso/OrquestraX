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
    Process.sleep(1000)

    # Generate mock result based on step type
    step_result = case step["type"] do
      "data_ingestion" -> %{"rows_read" => Enum.random(100..5000), "source" => "csv"}
      "processing" -> %{"clusters_found" => Enum.random(2..10), "accuracy" => 0.95}
      "archiving" -> %{"archive_path" => "s3://bucket/archive_#{System.unique_integer()}.zip"}
      _ -> %{"generic_result" => "ok"}
    end

    result = %{"status" => "success", "step_id" => step["id"], "worker" => inspect(Node.self())} |> Map.merge(step_result)

    # Report back to Orchestrator (Core)
    GenServer.cast(orchestrator_pid, {:step_completed, result})

    Logger.info("Step finished. Result sent back to orchestrator.")
  end
end

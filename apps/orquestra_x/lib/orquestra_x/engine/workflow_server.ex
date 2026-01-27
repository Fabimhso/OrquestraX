defmodule OrquestraX.Engine.WorkflowServer do
  use GenServer
  require Logger
  alias OrquestraX.Repo
  alias OrquestraX.Workflows.Instance
  alias OrquestraX.Workflows.Event

  # Client API

  def start_link(workflow_instance_id) do
    GenServer.start_link(__MODULE__, workflow_instance_id, name: via_tuple(workflow_instance_id))
  end

  def via_tuple(workflow_instance_id) do
    {:via, Registry, {OrquestraX.Registry, workflow_instance_id}}
  end

  def start_workflow(workflow_instance_id) do
    GenServer.cast(via_tuple(workflow_instance_id), :start)
  end

  # Server Callbacks

  @impl true
  def init(workflow_instance_id) do
    Logger.info("Starting WorkflowServer for instance #{workflow_instance_id}")
    # Load state from DB
    case Repo.get(Instance, workflow_instance_id) |> Repo.preload(:workflow_definition) do
      nil -> {:stop, :not_found}
      instance -> {:ok, %{instance: instance}}
    end
  end

  @impl true
  def handle_cast(:start, %{instance: instance} = state) do
    if instance.status == "pending" do
      Logger.info("Workflow #{instance.id} started")
      # Update DB
      {:ok, updated_instance} =
        instance
        |> Ecto.Changeset.change(status: "running")
        |> Repo.update()

      # Persist Event
      %Event{}
      |> Event.changeset(%{
        type: "started",
        timestamp: NaiveDateTime.utc_now(),
        workflow_instance_id: instance.id,
        payload: %{}
      })
      |> Repo.insert!()

      # Broadcast
      Phoenix.PubSub.broadcast(OrquestraX.PubSub, "workflows", {:workflow_updated, instance.id})
      Phoenix.PubSub.broadcast(OrquestraX.PubSub, "workflow:#{instance.id}", {:workflow_started, instance.id})

      # Dispatch first step
      steps = instance.workflow_definition.steps
      initial_step = Enum.at(steps, 0)

      if initial_step do
        OrquestraX.Dispatcher.dispatch(self(), initial_step, instance.context)
        {:noreply, %{state | instance: updated_instance}}
      else
        # Empty workflow, finish immediately
        finish_workflow(updated_instance, socket: nil) # No socket arg here, logic refactor needed? No, just helper.
         # Actually finish_workflow helper below
         {:noreply, state} # Placeholder, fix below
      end

    else
      Logger.warning("Workflow #{instance.id} already started or completed")
      {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:step_completed, result}, %{instance: instance} = state) do
    Logger.info("Workflow #{instance.id} step completed: #{inspect(result)}")

    # Persist Event
    %Event{}
    |> Event.changeset(%{
      type: "step_completed",
      timestamp: NaiveDateTime.utc_now(),
      workflow_instance_id: instance.id,
      payload: result
    })
    |> Repo.insert!()

    # Determine next step
    steps = instance.workflow_definition.steps
    next_index = instance.current_step_index + 1

    if next_index < length(steps) do
       # Dispatch next step
       next_step = Enum.at(steps, next_index)
       Logger.info("Dispatching next step [#{next_index}]: #{next_step["id"]}")

       {:ok, updated_instance} =
         instance
         |> Ecto.Changeset.change(current_step_index: next_index)
         |> Repo.update()

       OrquestraX.Dispatcher.dispatch(self(), next_step, instance.context)

       {:noreply, %{state | instance: updated_instance}}
    else
       # All steps completed
       {:ok, updated_instance} = finish_workflow(instance, result)
       {:noreply, %{state | instance: updated_instance}}
    end
  end

  defp finish_workflow(instance, result) do
    # Mark workflow as completed
    {:ok, updated_instance} =
        instance
        |> Ecto.Changeset.change(status: "completed")
        |> Repo.update()

    %Event{}
    |> Event.changeset(%{
      type: "completed",
      timestamp: NaiveDateTime.utc_now(),
      workflow_instance_id: instance.id,
      payload: %{}
    })
    |> Repo.insert!()

    # Broadcast
    Phoenix.PubSub.broadcast(OrquestraX.PubSub, "workflows", {:workflow_updated, instance.id})
    Phoenix.PubSub.broadcast(OrquestraX.PubSub, "workflow:#{instance.id}", {:workflow_completed, result})

    {:ok, updated_instance}
  end
end

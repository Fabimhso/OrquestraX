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
    case Repo.get(Instance, workflow_instance_id) do
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
      step = %{"id" => "step_1", "type" => "example_task"}
      OrquestraX.Dispatcher.dispatch(self(), step, instance.context)

      {:noreply, %{state | instance: updated_instance}}
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

    # Mark workflow as completed (Simple MVP logic)
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

    {:noreply, %{state | instance: updated_instance}}
  end
end

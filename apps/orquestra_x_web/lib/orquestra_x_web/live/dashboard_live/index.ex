defmodule OrquestraXWeb.DashboardLive.Index do
  use OrquestraXWeb, :live_view
  alias OrquestraX.Workflows

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(OrquestraX.PubSub, "workflows")
    end

    {:ok, assign(socket, instances: Workflows.list_instances())}
  end

  @impl true
  def handle_event("create_test_workflow", _params, socket) do
    # Create a dummy definition if not exists
    # We always create a new one to ensure it has multiple steps for this test
    # Or we can update the existing logic to check for a specific name
    definition_attrs = %{
      name: "Complex Workflow #{System.unique_integer()}",
      steps: [
        %{"id" => "step_1", "type" => "data_ingestion"},
        %{"id" => "step_2", "type" => "processing"},
        %{"id" => "step_3", "type" => "archiving"}
      ],
      version: 1
    }

    {:ok, def} = Workflows.create_definition(definition_attrs)

    {:ok, instance} = Workflows.create_instance(def.id, %{"some" => "data"})

    # Start it immediately
    OrquestraX.Engine.WorkflowServer.start_link(instance.id)
    OrquestraX.Engine.WorkflowServer.start_workflow(instance.id)

    {:noreply, put_flash(socket, :info, "Workflow created and started!")}
  end

  @impl true
  def handle_info({:workflow_updated, _id}, socket) do
    {:noreply, assign(socket, instances: Workflows.list_instances())}
  end

  defp status_color("running"), do: "text-green-900"
  defp status_color("completed"), do: "text-blue-900"
  defp status_color("failed"), do: "text-red-900"
  defp status_color(_), do: "text-gray-900"

  defp status_bg("running"), do: "bg-green-200"
  defp status_bg("completed"), do: "bg-blue-200"
  defp status_bg("failed"), do: "bg-red-200"
  defp status_bg(_), do: "bg-gray-200"
end

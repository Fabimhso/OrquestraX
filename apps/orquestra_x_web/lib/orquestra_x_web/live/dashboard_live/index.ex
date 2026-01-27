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
    {:ok, def} = case Workflows.list_definitions() do
      [] -> Workflows.create_definition(%{name: "Test Workflow", steps: [%{"id" => "step_1", "type" => "test"}], version: 1})
      [h | _] -> {:ok, h}
    end

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

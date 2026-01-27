defmodule OrquestraXWeb.WorkflowLive.Show do
  use OrquestraXWeb, :live_view
  alias OrquestraX.Workflows

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(OrquestraX.PubSub, "workflow:#{id}")
    end

    instance = Workflows.get_instance!(id)
    events = Workflows.list_events(id)

    {:ok, assign(socket, instance: instance, events: events)}
  end

  @impl true
  def handle_info({:workflow_started, _id}, socket) do
    refresh(socket)
  end

  def handle_info({:workflow_completed, _result}, socket) do
    refresh(socket)
  end

  # Catch-all for other events like step_completed if we broadcast them specifically
  def handle_info(_, socket), do: refresh(socket)

  defp refresh(socket) do
    id = socket.assigns.instance.id
    instance = Workflows.get_instance!(id)
    events = Workflows.list_events(id)
    {:noreply, assign(socket, instance: instance, events: events)}
  end

  defp status_class("running"), do: "bg-green-100 text-green-800"
  defp status_class("completed"), do: "bg-blue-100 text-blue-800"
  defp status_class("failed"), do: "bg-red-100 text-red-800"
  defp status_class(_), do: "bg-gray-100 text-gray-800"

  defp event_bg("started"), do: "bg-gray-400"
  defp event_bg("step_completed"), do: "bg-green-500"
  defp event_bg("completed"), do: "bg-blue-500"
  defp event_bg("failed"), do: "bg-red-500"
  defp event_bg(_), do: "bg-gray-300"
end

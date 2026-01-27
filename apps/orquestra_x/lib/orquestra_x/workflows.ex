defmodule OrquestraX.Workflows do
  @moduledoc """
  The Workflows context.
  """

  import Ecto.Query, warn: false
  alias OrquestraX.Repo
  alias OrquestraX.Workflows.Definition
  alias OrquestraX.Workflows.Instance
  alias OrquestraX.Workflows.Event

  def list_definitions do
    Repo.all(Definition)
  end

  def get_definition!(id), do: Repo.get!(Definition, id)

  def create_definition(attrs \\ %{}) do
    %Definition{}
    |> Definition.changeset(attrs)
    |> Repo.insert()
  end

  def list_instances do
    Repo.all(from i in Instance, preload: [:workflow_definition], order_by: [desc: i.inserted_at])
  end

  def get_instance!(id), do: Repo.get!(Instance, id) |> Repo.preload(:workflow_definition)

  def create_instance(definition_id, context \\ %{}) do
    %Instance{}
    |> Instance.changeset(%{
      status: "pending",
      context: context,
      workflow_definition_id: definition_id,
      current_step_index: 0
    })
    |> Repo.insert()
  end

  def list_events(instance_id) do
    Repo.all(from e in Event, where: e.workflow_instance_id == ^instance_id, order_by: [asc: e.timestamp])
  end
end

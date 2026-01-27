defmodule OrquestraX.Workflows.Instance do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workflows_instances" do
    field :status, :string, default: "pending"
    field :current_step_index, :integer, default: 0
    field :context, :map, default: %{}

    belongs_to :workflow_definition, OrquestraX.Workflows.Definition

    timestamps()
  end

  @doc false
  def changeset(instance, attrs) do
    instance
    |> cast(attrs, [:status, :current_step_index, :context, :workflow_definition_id])
    |> validate_required([:status, :workflow_definition_id])
    |> validate_inclusion(:status, ["pending", "running", "paused", "completed", "failed"])
  end
end

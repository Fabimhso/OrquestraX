defmodule OrquestraX.Workflows.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workflows_events" do
    field :type, :string
    field :payload, :map
    field :timestamp, :naive_datetime

    belongs_to :workflow_instance, OrquestraX.Workflows.Instance

    timestamps()
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:type, :payload, :timestamp, :workflow_instance_id])
    |> validate_required([:type, :workflow_instance_id])
  end
end

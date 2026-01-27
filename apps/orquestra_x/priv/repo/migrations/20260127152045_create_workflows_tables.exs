defmodule OrquestraX.Repo.Migrations.CreateWorkflowsTables do
  use Ecto.Migration

  def change do
    create table(:workflows_definitions) do
      add :name, :string, null: false
      add :steps, :map, null: false # JSONB array of steps
      add :version, :integer, default: 1
      add :description, :text

      timestamps()
    end

    create table(:workflows_instances) do
      add :workflow_definition_id, references(:workflows_definitions, on_delete: :nothing)
      add :status, :string, default: "pending"
      add :current_step_index, :integer, default: 0
      add :context, :map, default: %{} # Persistent state

      timestamps()
    end

    create table(:workflows_events) do
      add :workflow_instance_id, references(:workflows_instances, on_delete: :delete_all)
      add :type, :string, null: false
      add :payload, :map
      add :timestamp, :naive_datetime

      timestamps()
    end

    create index(:workflows_instances, [:status])
    create index(:workflows_events, [:workflow_instance_id])
  end
end

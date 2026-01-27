defmodule OrquestraX.Workflows.Definition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workflows_definitions" do
    field :name, :string
    field :steps, {:array, :map} # Using {:array, :map} if jsonb array of objects, or just :map? Postgres driver maps JSONB to Map usually. But migration said :map. Let's use :map (list of maps is a list, which is valid JSON).
    # Wait, in migration I used :map. JSONB can be object or array. Ecto usually handles `field :steps, {:array, :map}` for jsonb array, or just `field :steps, :map` if it's a generic JSON value.
    # Given migration `add :steps, :map`, it's generic map (JSON). I'll treat it as a list of steps in the application logic.
    field :version, :integer
    field :description, :string

    timestamps()
  end

  @doc false
  def changeset(definition, attrs) do
    definition
    |> cast(attrs, [:name, :steps, :version, :description])
    |> validate_required([:name, :steps])
  end
end

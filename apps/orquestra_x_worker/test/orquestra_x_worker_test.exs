defmodule OrquestraXWorkerTest do
  use ExUnit.Case
  doctest OrquestraXWorker

  test "greets the world" do
    assert OrquestraXWorker.hello() == :world
  end
end

defmodule GemExTest do
  use ExUnit.Case
  doctest GemEx

  test "greets the world" do
    assert GemEx.hello() == :world
  end
end

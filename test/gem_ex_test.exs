defmodule GemTest do
  use ExUnit.Case
  doctest Gem

  test "greets the world" do
    assert Gem.hello() == :world
  end
end

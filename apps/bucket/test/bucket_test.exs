defmodule BucketTest do
  use ExUnit.Case
  doctest Bucket

  test "greets the world" do
    assert Bucket.hello() == :world
  end
end

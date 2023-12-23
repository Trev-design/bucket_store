defmodule Bucket.Test.BucketRegistryTest do
  use ExUnit.Case, async: true

  test "spawn bucket" do
    assert {:error, _reason} = Bucket.Registry.lookup("shopping")
    Bucket.Registry.create("shopping")
    assert {:ok, bucket} = Bucket.Registry.lookup("shopping")
    Bucket.Access.put(bucket, "milk", 3)
    assert {:ok, 3} = Bucket.Access.get(bucket, "milk")
  end

  test "removes bucket on exit" do
    Enum.each(1..1000, fn _any ->
      Bucket.Registry.create("shopping")
      assert {:ok, bucket} = Bucket.Registry.lookup("shopping")
      GenServer.stop(bucket)
      assert {:error, _reason} = Bucket.Registry.lookup("shopping")
    end)
  end
end

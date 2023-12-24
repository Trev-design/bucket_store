defmodule Bucket.Test.BucketAccessTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = Bucket.Access.start_link([])
    %{bucket: bucket}
  end

  test "try to put more data in", %{bucket: bucket} do
    assert Bucket.Access.put(bucket, "milk", "2") == {:error, "value not an integer"}
    assert Bucket.Access.put(bucket, "milk", 2) == :ok
  end

  test "looking for the whole bucket", %{bucket: bucket} do
    assert Bucket.Access.show_bucket(bucket) == {:error, "bucket empty"}
    Bucket.Access.put(bucket, "milk", 3)
    Bucket.Access.put(bucket, "butter", 2)
    assert Bucket.Access.show_bucket(bucket) == {:ok, %{"milk" => 3, "butter" => 2}}
  end

  test "try to make a lookup in bucket", %{bucket: bucket} do
    assert Bucket.Access.get(bucket, "milk") == {:error, "bucket empty"}
    Bucket.Access.put(bucket, "milk", 3)
    assert Bucket.Access.get(bucket, "milk") == {:ok, 3}
    assert Bucket.Access.get(bucket, "milk2") == {:error, "no item with this name"}
  end

  test "try to delete an item", %{bucket: bucket} do
    Bucket.Access.put(bucket, "milk", 3)
    assert Bucket.Access.get(bucket, "milk") == {:ok, 3}
    Bucket.Access.delete_items(bucket, "milk")
    assert Bucket.Access.get(bucket, "milk") == {:error, "bucket empty"}
  end

  test "try to reduce item count", %{bucket: bucket} do
    Bucket.Access.put(bucket, "milk", 3)
    assert Bucket.Access.get(bucket, "milk") == {:ok, 3}
    assert Bucket.Access.reduce_count(bucket, "milk", -2) == {:error, "count value must be positive"}
    assert Bucket.Access.reduce_count(bucket, "butter", 5) == {:error, "no item with this name in this bucket"}
    assert Bucket.Access.reduce_count(bucket, "milk", "4") == {:error, "count not an integer"}
    assert Bucket.Access.reduce_count(bucket, "milk", 4) == {:error, "you don't have enough items in this bucket"}
    Bucket.Access.reduce_count(bucket, "milk", 2)
    assert Bucket.Access.get(bucket, "milk") == {:ok, 1}
    Bucket.Access.reduce_count(bucket, "milk", 1)
    assert Bucket.Access.get(bucket, "milk") == {:error, "bucket empty"}
  end
end

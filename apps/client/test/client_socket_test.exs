defmodule ClientSocketTest do
  use ExUnit.Case, async: true

  test "create bucket" do
    assert {:ok, _msg} = Client.Socket.create_bucket("cooking")
  end

  test "create and get socket failed" do
    assert {:ok, _msg} = Client.Socket.create_bucket("cooking")
    assert {:ok, "ERROR bucket empty"} = Client.Socket.get_bucket("cooking")
  end

  test "create and get whole bucket" do
    assert {:ok, _msg} = Client.Socket.create_bucket("cooking2")
    assert {:ok, "OK put new value in bucket"} = Client.Socket.put_in("cooking2", "fish", 2)
    assert {:ok, "OK {\"fish\":2}"} = Client.Socket.get_bucket("cooking2")
  end

  test "create and get key of a bucket failed" do
    assert {:ok, _msg} = Client.Socket.create_bucket("cooking3")
    assert {:ok, "ERROR bucket empty"} = Client.Socket.get_item("cooking3", "butter")
  end

  test "create and get key of a bucket" do
    assert {:ok, _msg} = Client.Socket.create_bucket("cooking4")
    assert {:ok, "OK put new value in bucket"} = Client.Socket.put_in("cooking4", "butter", 2)
    assert {:ok, "OK 2"} = Client.Socket.get_item("cooking4", "butter")
  end

  test "create and delete from bucket" do
    assert {:ok, _msg} = Client.Socket.create_bucket("cooking5")
    assert {:ok, "OK deleted value"} = Client.Socket.delete_item("cooking5", "milk")
    assert {:ok, "OK put new value in bucket"} = Client.Socket.put_in("cooking5", "milk", 2)
    assert {:ok, "OK {\"milk\":2}"} = Client.Socket.get_bucket("cooking5")
    assert {:ok, "OK deleted value"} = Client.Socket.delete_item("cooking5", "milk")
    assert {:ok, "ERROR bucket empty"} = Client.Socket.get_item("cooking5", "milk")
  end

  test "create and reduce item count failed" do
    assert {:ok, _msg} = Client.Socket.create_bucket("cooking6")
    assert {:ok, "ERROR no item with this name in this bucket"} = Client.Socket.reduce_item_count("cooking6", "tomatoes", 2)
  end

  test "create and reduce item count" do
    assert {:ok, _msg} = Client.Socket.create_bucket("cooking7")
    assert {:ok, "OK put new value in bucket"} = Client.Socket.put_in("cooking7", "milk", 3)
    assert {:ok, "OK reduced value"} = Client.Socket.reduce_item_count("cooking7", "milk", 2)
    assert {:ok, "OK {\"milk\":1}"} = Client.Socket.get_bucket("cooking7")
  end
end

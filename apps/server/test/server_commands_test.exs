defmodule ServerCommandsTest do
  use ExUnit.Case, async: true

  test "create bucket" do
    {:ok, {:create, _bucket} = command} = Server.Command.parse("CREATE bummel")
    assert {:ok, "created bucket"} = Server.Command.run_command(command)
  end

  test "show bucket failed" do
    {:ok, {:create, bucket} = command} = Server.Command.parse("CREATE bummel")
    {:ok, "created bucket"} = Server.Command.run_command(command)
    assert {:ok, command} = Server.Command.parse("SHOW #{bucket}")
    assert {:error, "bucket empty"} = Server.Command.run_command(command)
  end

  test "get bucket failed" do
    {:ok, {:create, bucket} = command} = Server.Command.parse("CREATE bimmel")
    {:ok, "created bucket"} = Server.Command.run_command(command)
    assert {:ok, command} = Server.Command.parse("GET #{bucket} invalid_key")
    assert {:error, "bucket empty"} = Server.Command.run_command(command)
  end

  test "put item in bucket get key and show bucket" do
    {:ok, {:create, bucket} = command} = Server.Command.parse("CREATE bemmel")
    {:ok, "created bucket"} = Server.Command.run_command(command)
    assert {:ok, command} = Server.Command.parse("PUT #{bucket} valid_key 42")
    assert :ok = Server.Command.run_command(command)
    assert {:ok, command} = Server.Command.parse("GET #{bucket} valid_key")
    assert {:ok, 42} = Server.Command.run_command(command)
    assert {:ok, command} = Server.Command.parse("SHOW #{bucket}")
    assert {:ok, %{"valid_key" => 42}} = Server.Command.run_command(command)
  end

  test "reduce count" do
    {:ok, {:create, bucket} = command} = Server.Command.parse("CREATE remmel")
    {:ok, "created bucket"} = Server.Command.run_command(command)
    assert {:ok, command} = Server.Command.parse("PUT #{bucket} valid_key 42")
    assert :ok = Server.Command.run_command(command)
    assert {:ok, command} = Server.Command.parse("REDUCE #{bucket} valid_key 41")
    assert :ok = Server.Command.run_command(command)
  end

  test "delete entry" do
    {:ok, {:create, bucket} = command} = Server.Command.parse("CREATE rammel")
    {:ok, "created bucket"} = Server.Command.run_command(command)
    assert {:ok, command} = Server.Command.parse("PUT #{bucket} valid_key 42")
    assert :ok = Server.Command.run_command(command)
    assert {:ok, command} = Server.Command.parse("DELETE #{bucket} valid_key")
    assert :ok = Server.Command.run_command(command)
  end

  test "invalid command" do
    {:ok, {:create, bucket} = command} = Server.Command.parse("CREATE rammel")
    {:ok, "created bucket"} = Server.Command.run_command(command)
    assert {:error, "command not found"} = Server.Command.parse("PeT #{bucket} valid_key 42")
  end
end

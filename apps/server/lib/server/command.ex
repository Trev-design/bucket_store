defmodule Server.Command do
  def parse(data) do
    case String.split(data) do
      ["CREATE", bucket]             -> {:ok, {:create, bucket}}
      ["SHOW", bucket]               -> {:ok, {:show, bucket}}
      ["GET", bucket, key]           -> {:ok, {:get, bucket, key}}
      ["PUT", bucket, key, value]    -> {:ok, {:put, bucket, key, value}}
      ["REDUCE", bucket, key, count] -> {:ok, {:reduce, bucket, key, count}}
      ["DELETE", bucket, key]        -> {:ok, {:delete, bucket, key}}
      _error                         -> {:error, "command not found"}
    end
  end

  def run_command({:create, bucket}) do
    Bucket.Registry.create(bucket)
    {:ok, "created bucket"}
  end

  def run_command({:show, bucket}) do
    lookup(bucket, fn pid ->
      Bucket.Access.show_bucket(pid)
    end)
  end

  def run_command({:get, bucket, key}) do
    lookup(bucket, fn pid ->
      Bucket.Access.get(pid, key)
    end)
  end

  def run_command({:put, bucket, key, value}) do
    lookup(bucket, fn pid ->
      Bucket.Access.put(pid, key, value)
    end)
  end

  def run_command({:reduce, bucket, key, count}) do
    lookup(bucket, fn pid ->
      Bucket.Access.reduce_count(pid, key, count)
    end)
  end

  def run_command({:delete, bucket, key}) do
    lookup(bucket, fn pid ->
      Bucket.Access.delete_items(pid, key)
    end)
  end

  defp lookup(bucket, callback) do
    case Bucket.Registry.lookup(bucket) do
      {:ok, pid} -> callback.(pid)
      error      -> error
    end
  end
end

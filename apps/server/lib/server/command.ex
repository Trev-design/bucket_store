defmodule Server.Command do
  @spec parse(binary()) ::
          {:error, binary()}
          | {:ok,
             {:create, binary()}
             | {:show, binary()}
             | {:delete, binary(), binary()}
             | {:get, binary(), binary()}
             | {:put, binary(), binary(), binary()}
             | {:reduce, binary(), binary(), binary()}}
  @doc """
  try to parse a command from command string.
  following commands are available.
  "CREATE bucket_name",
  "SHOW bucket_name",
  "GET bucket_name key",
  "PUT bucket_name key value",
  "REDUCE bucket key count",
  "DELETE bucket key".
  Other commands will get an error.
  This function is just a parser and is not going to make a hundret percent working command for an example:
  If you want to get a value on a key that does not exist the command does not work even though the command is correct.

  ## Examples:
      iex> Server.Command.parse("CREATE shopping")
      {:ok, {:create "shopping"}}

      iex> Server.Command.parse("SHOW shopping")
      {:ok, {:show "shopping"}}

      iex> Server.Command.parse("GET shopping milk")
      {:ok, {:get "shopping", "milk"}}

      iex> Server.Command.parse("PUT shopping butter 2")
      {:ok, {:put "shopping", "butter", "2"}}

      iex> Server.Command.parse("REUDCE shopping bananas 3")
      {:ok, {:reduce "shopping", "bananas", "3"}}

      iex> Server.Command.parse("DELETE shopping ananas")
      {:ok, {:delete "shopping", "ananas"}}

      iex> Server.Command.parse("INVALID shopping ananas")
      {:error, "command not found"}
  """
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

  @spec run_command(
          {:create, binary()}
          | {:show, binary()}
          | {:delete, binary(), any()}
          | {:get, binary(), any()}
          | {:put, binary(), any(), any()}
          | {:reduce, binary(), any(), any()}
        ) :: {:error, binary()} | {:ok, any()}
  @doc """
  Tries to run a command.
  Check out the Bucket.Access functions and the parse command to guarantee success.
  """
  def run_command({:create, bucket}) do
    Bucket.Registry.create(bucket)
    {:ok, "created bucket"}
  end

  def run_command({:show, bucket}) do
    lookup(bucket, fn pid ->
      case Bucket.Access.show_bucket(pid) do
        {:ok, content}    -> Jason.encode(content)
        {:error, reason}  -> {:error, reason}
      end
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
      {:ok, "put new value in bucket"}
    end)
  end

  def run_command({:reduce, bucket, key, count}) do
    lookup(bucket, fn pid ->
      case Bucket.Access.reduce_count(pid, key, count) do
        :ok -> {:ok, "reduced value"}
        err -> err
      end
    end)
  end

  def run_command({:delete, bucket, key}) do
    lookup(bucket, fn pid ->
      Bucket.Access.delete_items(pid, key)
      {:ok, "deleted value"}
    end)
  end

  defp lookup(bucket, callback) do
    case Bucket.Registry.lookup(bucket) do
      {:ok, pid} -> callback.(pid)
      error      -> error
    end
  end
end

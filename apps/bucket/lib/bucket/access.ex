defmodule Bucket.Access do
  use GenServer, restart: :temporary

  def start_link(opts), do: GenServer.start_link(__MODULE__, :ok, opts)

  @impl GenServer
  def init(:ok), do: {:ok, %{}}

  @spec get(bucket :: pid(), key :: binary()) ::
    {:ok, num_items :: non_neg_integer()} |
    {:error, reason :: binary()}
  @doc """
  Returns a tuple of an ok atom and the number of items on the given key when succeed,
  else it returns a tuple with an error atom and the reason.
  You can get an error because of your bucket is already empty or the item does not exist.

  ## Examples:
      iex> {:ok, bucket} = Bucket.Access.start_link([])
      {:ok, bucket}
      iex> Bucket.Access.put(bucket, "valid_key", 42)
      :ok
      iex> Bucket.Access.get(bucket, "valid_key")
      {:ok, 42}

      iex> Bucket.Access.get(bucket, "invalid_key")
      {:error, "no item with this name"}

      iex> {:ok, bucket2} = Bucket.Access.start_link([])
      {:ok, bucket2}
      iex> Bucket.Access.get(bucket2, "key")
      {:error, "bucket empty"}
  """
  def get(bucket, key), do: GenServer.call(bucket, {:get, key})

  @spec show_bucket(bucket :: pid()) :: items :: map()
  @doc """
  Returns the whole bucket if there is any item in it, else it returns an error

  ## Examples:
      iex> {:ok, bucket} = Bucket.Access.start_link([])
      {:ok, bucket}
      iex> Bucket.Access.put(bucket, "valid_key", 42)
      :ok
      iex> Bucket.Access.show_bucket(bucket)
      {:ok, %{"valid_key" => 42}}

      iex> {:ok, bucket2} = Bucket.Access.start_link([])
      {:ok, bucket2}
      iex> Bucket.Access.show_bucket(bucket2)
      {:error, "bucket empty"}
  """
  def show_bucket(bucket), do: GenServer.call(bucket, :show)

  @spec put(bucket :: pid(), key :: binary(), value :: non_neg_integer()) ::
    :ok | {:error, reason :: binary()}
  @doc """
  Returs an ok atom if succeed else an error.
  The value for the key must be an unsigned integer.
  If the key already exists the value will be added to the current.

  ## Examples
      iex> {:ok, bucket} = Bucket.Access.start_link([])
      {:ok, bucket}
      iex> Bucket.Access.put(bucket, "valid_key", 42)
      :ok
      iex> Bucket.Access.get(bucket, "valid_key")
      {:ok, 42}

      iex> Bucket.Access.put(bucket, "valid_key", 42)
      :ok
      iex> Bucket.Access.get(bucket, "valid_key")
      {:ok, 84}

      iex> {:ok, bucket2} = Bucket.Access.start_link([])
      {:ok, bucket2}
      iex> Bucket.Access.put(bucket2, "valid_key", "42")
      {:error, "value not an integer"}
  """
  def put(bucket, key, value), do: GenServer.call(bucket, {:set, key, value})

  @spec set_new_value(bucket :: pid(), key :: binary(), new_value :: non_neg_integer()) ::
    :ok, {:error, reason :: binary()}
  @doc """
  Overwrites the value of an entry and returns an ok tuple if succeed, if not it will return an error.
  The key must be existent and the value must be an unsigned inetger greater zero.

  ## Examples:
      iex> {:ok, bucket} = Bucket.Access.start_link([])
      {:ok, bucket}
      iex> Bucket.Access.put(bucket, "valid_key", 42)
      :ok
      iex> Bucket.Access.get(bucket, "valid_key")
      {:ok, 42}

      iex> Bucket.Access.set_new_value(bucket, "butter", 2)
      {:error, "key not found"}
      iex> Bucket.Access.set_new_value(bucket, "valid_key", "5")
      {:error, "value not an integer"}
      iex> Bucket.Access.set_new_value(bucket, "valid_key", -5)
      {:error, "value must be positive"}
      iex> Bucket.Access.set_new_value(bucket, "valid_key", 5)
      :ok

      iex> Bucket.Access.get(bucket, "valid_key")
      {:ok, 5}
  """
  def set_new_value(bucket, key, new_value), do: GenServer.call(bucket, {:new_value, key, new_value})

  @spec delete_items(bucket :: pid(), key :: binary()) :: :ok
  @doc """
  Returns just an ok atom.
  Does not matter if the key exist or not.
  If the key does not exist delete_items/2 just make no changes on the bucket.

  ## Examples:
      iex> {:ok, bucket} = Bucket.Access.start_link([])
      {:ok, bucket}
      iex> Bucket.Access.put(bucket, "valid_key", 42)
      :ok
      iex> Bucket.Access.show_bucket(bucket)
      {:ok, %{"valid_key" => 42}}
      iex> Bucket.Access.delete_items(bucket, "valid_key")
      :ok
      iex> Bucket.Access.show_bucket(bucket)
      {:error, "bucket empty"}

      iex> {:ok, bucket2} = Bucket.Access.start_link([])
      {:ok, bucket2}
      iex> Bucket.Access.put(bucket2, "valid_key", 42)
      :ok
      iex> Bucket.Access.show_bucket(bucket2)
      {:ok, %{"valid_key" => 42}}
      iex> Bucket.Access.delete_items(bucket, "valid_key2")
      :ok
      iex> Bucket.Access.show_bucket(bucket2)
      {:ok, %{"valid_key" => 42}}
  """
  def delete_items(bucket, key), do: GenServer.call(bucket, {:delete, key})

  @spec reduce_count(bucket :: pid(), key :: binary(), count :: non_neg_integer()) ::
    :ok | {:error, reason :: binary()}
  @doc """
  Reduces the count by the given key and returns an ok atom if succeed if not it returns an error.
  You will get an error if the count is not an integer or the value is negative or the new count become negative, but also if the key does not exists.
  It will deletes the whole entry if the count reached to zero.

  ## Examples:
      iex> {:ok, bucket} = Bucket.Access.start_link([])
      {:ok, bucket}
      iex> Bucket.Access.put(bucket, "valid_key", 42)
      :ok
      iex> Bucket.Access.show_bucket(bucket)
      {:ok, %{"valid_key" => 42}}
      iex> Bucket.Access.reduce_count(bucket, "valid_key", 21)
      :ok
      iex> Bucket.Access.show_bucket(bucket)
      {:ok, %{"valid_key" => 21}}
      iex> Bucket.Access.reduce_count(bucket, "valid_key", "21")
      {:error, "value not an integer"}
      iex> Bucket.Access.reduce_count(bucket, "valid_key", -21)
      {:error, "count value must be positive"}
      iex> Bucket.Access.reduce_count(bucket, "valid_key", 22)
      {:error, "you don't have enough items in this bucket"}
      iex> Bucket.Access.reduce_count(bucket, "valid_key", 21)
      :ok
      iex> Bucket.Access.show_bucket(bucket)
      {:error, "bucket empty"}
  """
  def reduce_count(bucket, key, count), do: GenServer.call(bucket, {:reduce, key, count})
  def finish(bucket), do: GenServer.call(bucket, :terminate)

  @impl GenServer
  def handle_call({:get, key}, _from, state) when map_size(state) > 0 do
    case Map.fetch(state, key) do
      {:ok, value} -> {:reply, {:ok, value}, state}
      :error       -> {:reply, {:error, "no item with this name"}, state}
    end
  end

  @impl GenServer
  def handle_call({:get, _key}, _from, state), do: {:reply, {:error, "bucket empty"}, state}

  @impl GenServer
  def handle_call(:show, _from, state)when map_size(state) > 0, do: {:reply, {:ok, state}, state}

  @impl GenServer
  def handle_call(:show, _from, state), do: {:reply, {:error, "bucket empty"}, state}

  @impl GenServer
  def handle_call({:set, key, value}, _from, state) when is_integer(value) do
    if value > 0 do
      put_value_in(state, key, value)
    else
      {:reply, {:error, "value must be positive"}, state}
    end
  end

  @impl GenServer
  def handle_call({:set, _key, _value}, _from, state) do
    {:reply, {:error, "value not an integer"}, state}
  end

  @impl GenServer
  def handle_call({:new_value, key, new_value}, _from, state) when is_integer(new_value) do
    if new_value > 0 do
      try_set_new_value(state, key, new_value)
    else
      {:reply, {:error, "value must be positive"}, state}
    end
  end

  @impl GenServer
  def handle_call({:new_value, _key, _new_value}, _from, state) do
    {:reply, {:error, "value not an integer"}, state}
  end

  @impl GenServer
  def handle_call({:delete, key}, _from, state), do: {:reply, :ok, Map.delete(state, key)}

  @impl GenServer
  def handle_call({:reduce, key, count}, _from, state) when is_integer(count) do
    case Map.fetch(state, key) do
      {:ok, current} -> reduce(state, key, current, count)
      :error         -> {:reply, {:error, "no item with this name in this bucket"}, state}
    end
  end

  @impl GenServer
  def handle_call({:reduce, _key, _count}, _from, state) do
    {:reply, {:error, "count not an integer"}, state}
  end

  @impl GenServer
  def handle_call(:terminate, _from, state) do
    {:stop, :normal, {:ok, state}, state}
  end

  defp put_value_in(state, key, value) do
    case Map.fetch(state, key) do
      {:ok, current} -> {:reply, :ok, Map.put(state, key, current + value)}
      :error         -> {:reply, :ok, Map.put(state, key,value)}
    end
  end

  defp try_set_new_value(state, key, new_value) do
    case Map.fetch(state, key) do
      {:ok, _value} -> {:reply, :ok, Map.put(state, key, new_value)}
      :error        -> {:reply, {:error, "key not found"}, state}
    end
  end

  defp reduce(state, _key, _current, count) when count < 0 do
    {:reply, {:error, "count value must be positive"}, state}
  end

  defp reduce(state, _key, current, count) when current - count < 0 do
    {:reply, {:error, "you don't have enough items in this bucket"}, state}
  end

  defp reduce(state, key, current, count) do
    new_count = current - count
    if new_count == 0 do
      {:reply, :ok, Map.delete(state, key)}
    else
      {:reply, :ok, Map.put(state, key, new_count)}
    end
  end
end

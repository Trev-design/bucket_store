defmodule Bucket.Access do
  use GenServer, restart: :temporary

  def start_link(opts), do: GenServer.start_link(__MODULE__, :ok, opts)

  @impl GenServer
  def init(:ok), do: {:ok, %{}}

  @spec get(bucket :: pid(), key :: binary()) ::
    {:ok, num_items :: non_neg_integer()} |
    {:error, reason :: binary()}
  def get(bucket, key), do: GenServer.call(bucket, {:get, key})

  @spec show_bucket(bucket :: pid()) :: items :: map()
  def show_bucket(bucket), do: GenServer.call(bucket, :show)

  @spec put(bucket :: pid(), key :: binary(), value :: non_neg_integer()) ::
    :ok | {:error, reason :: binary()}
  def put(bucket, key, value), do: GenServer.call(bucket, {:set, key, value})

  @spec delete_items(bucket :: pid(), key :: binary()) :: :ok
  def delete_items(bucket, key), do: GenServer.call(bucket, {:delete, key})

  @spec reduce_count(bucket :: pid(), key :: binary(), count :: non_neg_integer()) ::
    :ok | {:error, reason :: binary()}
  def reduce_count(bucket, key, count), do: GenServer.call(bucket, {:reduce, key, count})
  def finish(bucket), do: GenServer.call(bucket, :terminate)

  @impl GenServer
  def handle_call({:get, key}, _from, state) do
    case Map.fetch(state, key) do
      {:ok, value} -> {:reply, {:ok, value}, state}
      :error       -> {:reply, {:error, "no item with this name"}, state}
    end
  end

  @impl GenServer
  def handle_call(:show, _from, state), do: {:reply, state, state}

  @impl GenServer
  def handle_call({:set, key, value}, _from, state) when is_integer(value) do
    case Map.fetch(state, key) do
      {:ok, current} -> {:reply, :ok, Map.put(state, key, current + value)}
      :error         -> {:reply, :ok, Map.put(state, key,value)}
    end
  end

  @impl GenServer
  def handle_call({:set, _key, _value}, _from, state) do
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

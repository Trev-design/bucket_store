defmodule Bucket.Access do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, :ok, opts)
  def init(:ok), do: {:ok, %{}}

  def get(bucket, key), do: GenServer.call(bucket, {:get, key})
  def show_bucket(bucket), GenServer.call(bucket, :show)
  def put(bucket, key, value), do: GenServer.call(bucket, {:set, key, value})
  def delete_items(bucket, key), GenServer.call(bucket, {:delete, key})
  def reduce_count(bucket, key, count), GenServer.call(bucket, {:reduce, key, count})
  def finish(bucket), GenServer.call(bucket, :terminate)

  def handle_call({:get, key}, _from, state) do
    case Map.fetch(state, key) do
      {:ok, value} -> {:reply, {:ok, value}, state}
      :error       -> {:reply, {:error, "no item with this name"}}
    end
  end

  def handle_call(:show, _from, state), do: {:reply, state, state}

  def handle_call({:set, key, value}, _from, state) do
    case Map.fetch(state, key) do
      {:ok, current} -> {:reply, :ok, Map.put(state, key, current + value)}
      :error         -> {:reply, :ok, Map.put(state, key,value)}
    end
  end

  def handle_call({:delete, key}, _from, state), do: {:reply, :ok, Map.delete(state, key)}

  def handle_call({:reduce, key, count}, _from, state) do
    case Map.fetch(state, key) do
      {:ok, current} -> reduce(state, key, current, count)
      :error         -> {:reply, {:error, "no item with this name in this bucket"}, state}
    end
  end

  def handle_call(:terminate, _from, state) do
    {:reply, state, state, {:continue, :finish_process}}
  end

  def handle_continue(:finish_process, state), do: {:stop, :normal, state}

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

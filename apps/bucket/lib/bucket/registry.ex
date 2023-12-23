defmodule Bucket.Registry do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, :ok, opts)

  @impl GenServer
  def init(:ok) do
    :ets.new(:registries, [:named_table, read_concurrency: true])
    :ets.new(:refs, [:named_table, read_concurrency: true])
    {:ok, :ok}
  end

  @spec lookup(name :: binary()) ::
    {:ok, bucket :: pid()} |
    {:error, reason :: binary()}
  def lookup(name), do: GenServer.call(__MODULE__, {:lookup, name})

  @spec create(name :: binary()) :: :ok
  def create(name), do: GenServer.cast(__MODULE__, {:create, name})

  @impl GenServer
  def handle_call({:lookup, name}, _from, state) do
    case :ets.lookup(:registries, name) do
      []                -> {:reply, {:error, "no bucket registered with this name"}, state}
      [{^name, bucket}] -> {:reply, {:ok, bucket}, state}
    end
  end

  @impl GenServer
  def handle_cast({:create, name}, state) do
    case :ets.member(:registries, name) do
      true  -> {:noreply, state}
      _else ->
        {:ok, bucket} = DynamicSupervisor.start_child(BucketAccess.Supervisor, Bucket.Access)
        ref = Process.monitor(bucket)
        :ets.insert(:registries, {name, bucket})
        :ets.insert(:refs, {ref, name})
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    [{^ref, name}] = :ets.lookup(:refs, ref)
    :ets.delete(:registries, name)
    :ets.delete(:refs, ref)
    {:noreply, state}
  end
end

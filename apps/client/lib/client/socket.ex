defmodule Client.Socket do
  use GenServer

  def start_link([name: name, port: port]) do
    GenServer.start_link(__MODULE__, port, name: name)
  end

  @impl GenServer
  def init(port) do
    :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false])
  end

  @spec create_bucket(bucket_name :: binary()) :: {:ok, msg :: binary()} | {:error, msg :: binary()}
  @doc """
  send a command to the server to create a bucket
  """
  def create_bucket(bucket_name), do: GenServer.call(__MODULE__, {:create_bucket, bucket_name})

  @spec get_bucket(bucket :: binary()) :: {:ok, msg :: binary()} | {:error, msg :: binary()}
  @doc """
  send a command to the sever to get the whole bucket
  """
  def get_bucket(bucket_name), do: GenServer.call(__MODULE__, {:get_bucket, bucket_name})

  @spec get_item(bucket_name :: binary(), key :: binary()) :: {:ok, msg :: binary()} | {:error, msg :: binary()}
  @doc """
  send a command to the server to get a specific item of the bucket
  """
  def get_item(bucket_name, key), do: GenServer.call(__MODULE__, {:get_item, bucket_name, key})

  @spec put_in(bucket_name :: binary(), key :: binary(), value :: non_neg_integer()) :: {:ok, msg :: binary()} | {:error, msg :: binary()}
  @doc """
  send a command to the server to set a new item count or adds new items to a existing count
  """
  def put_in(bucket_name, key, value), do: GenServer.call(__MODULE__, {:put_in, bucket_name, key, value})

  @spec reduce_item_count(bucket_name :: binary(), key :: binary(), count_down :: non_neg_integer()) :: {:ok, msg :: binary()} | {:error, msg :: binary()}
  @doc """
  send a command to the server to reduce the count of a specific item
  """
  def reduce_item_count(bucket_name, key, items_down), do: GenServer.call(__MODULE__, {:reduce_count, bucket_name, key, items_down})

  @spec delete_item(bucket_name :: binary(), key :: binary()) :: {:ok, msg :: binary()} | {:error, msg :: binary()}
  @doc """
  send a command to the server to delete an complete item count
  """
  def delete_item(bucket_name, key), do: GenServer.call(__MODULE__, {:delete_item, bucket_name, key})

  @impl GenServer
  def handle_call({:create_bucket, bucket_name}, _from, socket) do
    compute_packet(socket, <<"CREATE #{bucket_name}">>)
  end

  @impl GenServer
  def handle_call({:get_bucket, bucket_name}, _from, socket) do
    compute_packet(socket, <<"SHOW #{bucket_name}">>)
  end

  @impl GenServer
  def handle_call({:get_item, bucket_name, key}, _from, socket) do
    compute_packet(socket, <<"GET #{bucket_name} #{key}">>)
  end

  @impl GenServer
  def handle_call({:put_in, bucket_name, key, value}, _from, socket) do
    compute_packet(socket, <<"PUT #{bucket_name} #{key} #{value}">>)
  end

  @impl GenServer
  def handle_call({:reduce_count, bucket_name, key, value}, _from, socket) do
    compute_packet(socket, <<"REDUCE #{bucket_name} #{key} #{value}">>)
  end

  @impl GenServer
  def handle_call({:delete_item, bucket_name, key}, _from, socket) do
    compute_packet(socket, <<"DELETE #{bucket_name} #{key}">>)
  end

  defp compute_packet(socket, packet) do
    case :gen_tcp.send(socket, packet) do
      :ok -> {:reply, :gen_tcp.recv(socket, 0), socket}
      invalid -> {:reply, invalid, socket}
    end
  end
end

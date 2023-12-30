defmodule Client.Socket do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, :ok, opts)
  def init(_init_arg) do
    {:ok, socket} = :gen_tcp.connect({0,0,0,0}, 4040, [:binary, active: false, packet: :line])

    {:ok, socket}
  end

  def create_bucket(bucket_name), do: GenServer.call(__MODULE__, {:create_bucket, bucket_name})
  def get_bucket(bucket_name), do: GenServer.call(__MODULE__, {:get_bucket, bucket_name})
  def get_item(bucket_name, key), do: GenServer.call(__MODULE__, {:get_item, bucket_name, key})
  def put_in(bucket_name, key, value), do: GenServer.call(__MODULE__, {:put_in, bucket_name, key, value})
  def reduce_item_count(bucket_name, key, items_down), do: GenServer.call(__MODULE__, {:reduce_count, bucket_name, key, items_down})
  def delete_item(bucket_name, key), do: GenServer.call(__MODULE__, {:delete_item, bucket_name, key})

  def handle_call({:create_bucket, bucket_name}, _from, socket) do
    compute_packet(socket, "CREATE #{bucket_name}")
  end

  def handle_call({:get_bucket, bucket_name}, _from, socket) do
    compute_packet(socket, "SHOW #{bucket_name}")
  end

  def handle_call({:get_item, bucket_name, key}, _from, socket) do
    compute_packet(socket, "GET #{bucket_name} #{key}")
  end

  def handle_call({:put_in, bucket_name, key, value}, _from, socket) do
    compute_packet(socket, "PUT #{bucket_name} #{key} #{value}")
  end

  def handle_call({:reduce_count, bucket_name, key, value}, _from, socket) do
    compute_packet(socket, "REDUCE #{bucket_name} #{key} #{value}")
  end

  def handle_call({:delete_item, bucket_name, key}, _from, socket) do
    compute_packet(socket, "DELETE #{bucket_name} #{key}")
  end

  defp compute_packet(socket, packet) do
    case :gen_tcp.send(socket, packet) do
      :ok -> {:reply, :gen_tcp.recv(socket, 0), socket}
      invalid -> {:reply, invalid, socket}
    end
  end
end

defmodule Server.Socket do
  require Logger

  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(BucketServer.TaskSupervisor, fn -> serve(client) end)
    :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> message()
    |> write_line(socket)

    serve(socket)
  end

  defp message(socket) do
    with {:ok, data}    <- :gen_tcp.recv(socket, 0),
         {:ok, command} <- Server.Command.parse(data)
    do
      Server.Command.run_command(command)
    else
      err -> err
    end
  end

  defp write_line({:ok, message}, socket), do: :gen_tcp.send(socket, "OK #{message}")
  defp write_line({:error, message}, socket), do: :gen_tcp.send(socket, "ERROR #{message}")
end

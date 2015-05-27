defmodule Venus do
  def start do
    port = 3000
    {:ok, socket} = :gen_tcp.listen(port,[:binary,{:packet, 0},{:active, false}])
    IO.puts "INFO: Started socket on port: #{port}"
    server(socket)
  end

  def server(socket) do
    #state = %{username: "Player1", wallet: %{diamonds: 100, oil: 100, gold: 100}}
    #state = put_in(state.wallet.diamonds, state.wallet.diamonds - 10)
    Process.register(self(), :main)
    state = %{}
    Venus_watcher.new(socket)
    IO.puts "INFO: Server Initialized"
    Venus.server(socket,state)
  end

  def server(socket, state) do
    receive do
      {:shutdown} ->
        :gen_tcp.shutdown(socket,:read_write)
        IO.puts "INFO: Server Shutdown"
      {:con_made} ->
        IO.puts "INFO: A new connection was received"
        Venus.server(socket,state)
      {:con_closed} ->
        IO.puts "INFO: Unconfigured Connection closed"
        Venus.server(socket,state)
      {:register,name,sender} ->
        case get_in(state,[name, :pid]) do
          nil ->
            newstate = put_in(state["#{name}"].pid, sender)
            send(sender,{:ok})
            IO.puts "INFO: Server-#{name} has registered with Venus"
            Venus.server(socket,newstate)
          _ ->
            send(sender,{:error})
            Venus.server(socket,state)
        end
        IO
      _ ->
        IO.puts "ERROR: Unexpected command"
        send(self(), {:shutdown})
        Venus.server(socket,state)
    end
  end
end

defmodule Venus_watcher do
  def new(socket) do
    spawn(Venus_watcher,:new,[socket])
  end

  def sock_watcher(socket) do
    {:ok, con} = :gen_tcp.accept(socket)
    send(:main, {:connection})
    Venus_watcher.new(socket)
    handle_connection(con)
  end

  def handle_connection(connection) do
    case :gen_tcp.recv(connection,0) do
      {:ok, data} ->
        msg = String.strip(data)
        case msg do
          "register,"<>name ->
            send(:main,{:register,name,self()})
            receive do
              {:ok} ->
                Venus_Serverman.new(connection,name)
              {:error} ->
                :gen_tcp.send(connection, :erlang.bitstring_to_list("Server name taken"))
                Venus_watcher.handle_connection(connection)
            end
          _ ->
            :gen_tcp.send(connection, :erlang.bitstring_to_list("Invalid packet"))
        end
        Venus_watcher.handle_connection(connection)
      _ ->
        send(:main,{:con_closed})
    end
  end

end

defmodule Venus_Serverman do
  def new(connection,name) do

  end


end

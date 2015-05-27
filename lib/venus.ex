defmodule Venus do
  defstruct name: "", pid: nil
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
      {:con_closed, name} ->
        newstate = Map.delete(state, "#{name}")
        IO.puts "INFO: Server-#{name} has disconnected"
        Venus.server(socket,newstate)
      {:register,name,sender} ->
        case state["#{name}"] do
          nil ->
            newserver = %Venus{name: "#{name}", pid: sender}
            newstate = put_in(state["#{name}"], newserver )
            IO.puts "INFO: Server-#{name} has registered"
            send(sender,{:ok})
            Venus.server(socket,newstate)
          _ ->
            send(sender,{:error})
            Venus.server(socket,state)
        end
      _err ->
        IO.puts "ERROR: Unexpected command"
        IO.puts _err
        send(self(), {:shutdown})
        Venus.server(socket,state)
    end
  end
end


defmodule Venus_watcher do
  def new(socket) do
    spawn(Venus_watcher,:sock_watcher,[socket])
  end

  def sock_watcher(socket) do
    {:ok, con} = :gen_tcp.accept(socket)
    send(:main, {:con_made})
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
                :gen_tcp.send(connection, :erlang.bitstring_to_list("Welcome #{name}"))
                Venus_Serverman.new(connection,name)
              {:error} ->
                :gen_tcp.send(connection, :erlang.bitstring_to_list("Server name taken"))
                Venus_watcher.handle_connection(connection)
            end
          _ ->
            :gen_tcp.send(connection, :erlang.bitstring_to_list("Invalid packet"))
            Venus_watcher.handle_connection(connection)
        end
        Venus_watcher.handle_connection(connection)
      {_,con} ->
        case con do
          connection ->
            send(:main,{:con_closed})
          _ ->
            Venus_watcher.handle_connection(connection)
        end
    end
  end

end

defmodule Venus_Serverman do
  def new(connection,name) do
    :inet.setopts(connection, [{:active, :true}])
    Venus_Serverman.loop(connection,name)
  end

  def loop(connection, name) do
    receive do
      {:tcp_closed,con} ->
        send(:main,{:con_closed,name})
    end
  end

end

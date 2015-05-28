#Main process running the program.
#This starting point will load any config* options, as well as setup and configure the socket.
# It is also the main routing module, so it will take messages from the different servers and route
# them appropriately. It is strictly for routing and keeping master state. Because shared state is for the children(and other languages)
#todo:
# - Specification of configuration + code to make it work; because duh.
# - Make this thing a gen_server nerd, it will obviously optimize the hell out of it, plus make this garbage code skimmable.

defmodule Venus do
  def start do
    port = 3000
    {:ok, socket} = :gen_tcp.listen(port,[:binary,{:packet, 0},{:active, false}])
    IO.puts "INFO: Started socket on port: #{port}"
    server(socket)
  end

  def server(socket) do
    Process.register(self(), :main)
    state = %{}
    Venus_Watcher.new(socket)
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
            newserver = %GameServer{name: "#{name}", pid: sender}
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

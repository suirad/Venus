#Main process running the program.
#This starting point will load any config* options, as well as setup and configure the socket.
# It is also the main routing module, so it will take messages from the different servers and route
# them appropriately. It is strictly for routing and keeping master state. Because shared state is for the children(and other languages)
#todo:
# - Specification of configuration + code to make it work; because duh.
# - Make this thing a gen_server nerd, it will obviously refactor the hell out of it, plus make this garbage code skimmable.
# - Possibly changing the gameserver structure to a record, that could probably be better in use. Il need to test it...

defmodule Venus do
  def start do
    port = 3000
    case :gen_tcp.listen(port,[:binary,{:packet, :line},{:active, false}]) do
      {:ok, socket} ->
        IO.puts "INFO: Started socket on port: #{port}"
        server(socket)
      _err ->
        IO.puts "ERROR: Unable to bind to port"
    end
  end

  def server(socket) do
    Process.register(self(), :venus)
    state = %{}
    Venus.Watcher.new(socket)
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
        IO.puts "INFO: Server: #{name} has disconnected"
        Venus.server(socket,newstate)
      {:register,name,sender} ->
        case state["#{name}"] do
          nil ->
            newserver = %Venus.Server{name: "#{name}", pid: sender}
            newstate = put_in(state["#{name}"], newserver )
            IO.puts "INFO: Server-#{name} has registered"
            send(sender,{:ok})
            Venus.server(socket,newstate)
          _ ->
            send(sender,{:error})
            IO.puts "WARN: Server attempted to reuse name: #{name}"
            Venus.server(socket,state)
        end
      {:route,server,plugin,message} ->
        case state["#{server}"] do
          nil ->
            IO.puts("WARN: Dropped message - Server '#{server}' doesn't exist")
            Venus.server(socket,state)
          gameserver ->
            #IO.puts "Routing to #{server}:#{plugin}>#{message}"
            send(gameserver.pid,{:msg,plugin,message})
            Venus.server(socket, state)
        end
      _err ->
        IO.puts "ERROR: Unexpected command"
        IO.puts _err
        send(self(), {:shutdown})
        Venus.server(socket,state)
    end
  end
end

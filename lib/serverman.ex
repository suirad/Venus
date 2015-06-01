#This process is the process that handles each individual gameserver connection, 1 for 1.
# It does everything as far as handling packets sent to and from the gameservers, as well as responding to
# and handling malformed/invalid packets before they bother the venus process. Its pretty cool.
# I am tired of writing comments and am going back to coding so i can actually finish this sometime soon.
#todo:

defmodule Venus.Serverman do
  def new(connection) do
    spawn(Venus.Serverman,:handle_connection,[connection])
  end

  def handle_connection(connection) do
    case :gen_tcp.recv(connection,0) do
      {:ok, data} ->
        msg = String.strip(data)
        case msg do
          "register,"<>name ->
            send(:venus,{:register,name,self()})
            receive do
              {:ok} ->
                :gen_tcp.send(connection, 'welcome\n')
                loop(connection,name)
              {:error} ->
                :gen_tcp.send(connection, 'Server name taken\n')
                handle_connection(connection)
            end
          _ ->
            :gen_tcp.send(connection, 'Invalid packet\n')
            IO.puts "Invalid packet"
            IO.inspect msg
            handle_connection(connection)
        end
      _err ->
        send(:venus,{:con_closed})
    end
  end

  def loop(connection, name) do
    :inet.setopts(connection, active: :once)
    receive do
      {:die} ->
        :gen_tcp.send(connection, 'Connection closed\n')
        :gen_tcp.close(connection)
      {:tcp_closed,_con} ->
        send(:venus,{:con_closed,name})
      {:tcp,connection,data} ->
        msg = handle_packet(String.strip(data))
        case msg do
          {:msg, server, plugin, message} ->
            send(:venus,{:route,server,plugin,message})
          {:error, reason} ->
            :gen_tcp.send(connection, 'Message refused: #{reason} | Message: #{data}\n')
        end
        loop(connection,name)

      {:msg,plugin,msg} ->
        :gen_tcp.send(connection,'msg,#{plugin},#{msg}\n')
        loop(connection,name)

      _err ->
        IO.puts _err
    end
  end

  #return {:ok, server, plugin, message} or {:error, reason}
  def handle_packet(data) do
    case data do
      "msg,"<>rest ->
        case String.split(rest,",", parts: 3) do
          [server, plugin, msg] ->
            {:msg,server,plugin,msg}
          _err ->
            {:error, "Invalid Message"}
        end
      _err ->
        {:error, "Invalid Packet"}
    end
  end

end

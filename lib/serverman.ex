#This process is the process that handles each individual gameserver connection, 1 for 1.
# It does everything as far as handling packets sent to and from the gameservers, as well as responding to
# and handling malformed/invalid packets before they bother the main process. Its pretty cool.
# I am tired of writing comments and am going back to coding so i can actually finish this sometime soon.

defmodule Venus_Serverman do
  def new(connection) do
    spawn(Venus_Serverman,:handle_connection,[connection])
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
                config_loop(connection,name)
              {:error} ->
                :gen_tcp.send(connection, :erlang.bitstring_to_list("Server name taken"))
                handle_connection(connection)
            end
          _ ->
            :gen_tcp.send(connection, :erlang.bitstring_to_list("Invalid packet"))
            handle_connection(connection)
        end
      _err ->
        send(:main,{:con_closed})
        IO.puts("#{_err}")
    end
  end

  def config_loop(connection, name) do
    :inet.setopts(connection, [{:active, :true}])
    loop(connection,name)
  end

  def loop(connection, name) do
    receive do
      {:tcp_closed,con} ->
        send(:main,{:con_closed,name})
    end
  end

end

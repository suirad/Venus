#This process is the socket watcher. What it does is watch the socket for new connnections, then it spawns a
# new process to handle each new connection, then continues its job. Its pretty simple but really powerful.
# This process alone, can handle up to roughly 1k mass connections at a time.
# What is pretty cool, is that all that is needed for it to handle more connections, is just
# spawning more watcher processes, which is as simple as: Venus_Watcher.new(socket)
# Money.

defmodule Venus_Watcher do
  def new(socket) do
    spawn(Venus_Watcher,:sock_watcher,[socket])
  end

  def sock_watcher(socket) do
    {:ok, con} = :gen_tcp.accept(socket)
    pid = Venus_Serverman.new(con)
    :gen_tcp.controlling_process(con, pid)
    send(:main, {:con_made})
    sock_watcher(socket)
  end

end

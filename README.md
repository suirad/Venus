Venus
=====
##Introduction:##
Venus is a concurrent message routing server to support game servers made in Elixir. Its purpose is to support Minecraft Bukkit plugins communicate with each other cross-server. Although, it is generic enough to be used for any sort of similar service. The generic-ness of it will also make it rather easy to hook additional applications/web services into the router, so that they may communicate with the servers/plugins.

The current implementation will be supported by a bukkit plugin that handles the communication for other bukkit plugins.

##How to use:##
**• Install the latest Elixir**

**• Clone the current repo**

**• Navigate to the project folder in a command window and type the command to compile:** mix run

**• Then start the Elixir interactive interface:** iex -S mix

**• Finally start the routing server:** Venus.start

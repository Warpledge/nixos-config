#=====================================================================#
# MINECRAFT SERVERS
#=====================================================================#
#- Home-manager modules for each Minecraft server managed on this host.
#- Add a new server by creating a .nix file here and importing it below.
{...}: {
  imports = [
    ./gtnh-server.nix
    ./tfg-server.nix
    ./mcservers.nix
  ];
}

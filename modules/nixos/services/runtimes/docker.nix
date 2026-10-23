#=====================================================================#
# DOCKER CONTAINERIZATION
#=====================================================================#
{
  lib,
  pkgs,
  machine,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Docker Service & Configuration
  #--------------------------------------------------------------------#
  virtualisation.docker = {
    enable = true;
    # Run Docker daemon without requiring sudo for docker group
    rootless.enable = true;
    # Automatically start Docker daemon on boot
    autoPrune.enable = true;
    autoPrune.dates = "weekly";
  };

  #--------------------------------------------------------------------#
  #-- Docker Compose
  #--------------------------------------------------------------------#
  environment.systemPackages = with pkgs; [
    docker-compose
  ];

  #--------------------------------------------------------------------#
  #-- User Configuration
  #--------------------------------------------------------------------#
  users.groups.docker = {
    members = lib.attrNames (lib.filterAttrs (_: user: user.admin) machine.users);
  };
}

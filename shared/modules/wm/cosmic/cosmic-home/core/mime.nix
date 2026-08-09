#=====================================================================#
# COSMIC DEFAULT APPLICATION FIX
#=====================================================================#
{config, ...}: {
  #--------------------------------------------------------------------#
  #-- Desktop-Prefixed mimeapps.list
  #--------------------------------------------------------------------#
  # COSMIC reads ~/.config/cosmic-mimeapps.list before ~/.config/mimeapps.list
  # and only ever writes the former, seeding it once on first login. Without
  # this, defaults from home-manager/mime.nix freeze at that first snapshot.
  #
  # Makes the file a read-only symlink, so Settings -> Default Applications
  # can no longer write: change defaults in mime.nix, not the GUI.
  xdg.configFile."cosmic-mimeapps.list" = {
    force = true;
    source = config.xdg.configFile."mimeapps.list".source;
  };
}

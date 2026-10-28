#=====================================================================#
# ENVIRONMENT VARIABLES
#=====================================================================#
#- Variables set on Omni Settings' Startup page, for every program the
#- session starts
{
  lib,
  user,
  ...
}: {
  # Wins over a module's own value for the same variable (EDITOR in variables.nix)
  home.sessionVariables = lib.mapAttrs (_: lib.mkOverride 90) user.env;
}

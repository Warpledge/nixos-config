#=====================================================================#
# ENVIRONMENT VARIABLES
#=====================================================================#
#- Variables set on Omni Settings' Startup page, for every program the
#- session starts
{user, ...}: {
  home.sessionVariables = user.env;
}

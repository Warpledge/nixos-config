#=====================================================================#
# PROGRAM OPTIONS
#=====================================================================#
{...}: {
  #--- Options
  programs = {
    dircolors = {
      enable = true;
    };
  };

  #--- Disable manuals - nmd fails to build often
  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };
}

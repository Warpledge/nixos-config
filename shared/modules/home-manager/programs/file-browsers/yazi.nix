#=====================================================================#
# YAZI TERMINAL FILE MANAGER CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Program
  #--------------------------------------------------------------------#
  # Theming is handled by the Catppuccin home-manager port (Mocha Mauve);
  # the matching Stylix yazi target is disabled to avoid a conflict.
  # The `y` shell wrapper changes the working directory to the last
  # location browsed when Yazi exits.

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    #-- Settings
    settings = {
      mgr = {
        show_hidden = false;
        sort_by = "natural";
        sort_dir_first = true;
        linemode = "size";
      };
      preview = {
        max_width = 1000;
        max_height = 1000;
      };
    };
  };

  #--------------------------------------------------------------------#
  #-- Preview Dependencies
  #--------------------------------------------------------------------#
  # CLI tools Yazi shells out to for rich file previews.

  home.packages = with pkgs; [
    ffmpegthumbnailer # video thumbnails
    poppler-utils # PDF previews
    jq # JSON previews
    fd # file finder (filtering)
    ripgrep # content search
  ];
}

#=====================================================================#
# FZF CONFIGURATION
#=====================================================================#
{lib, ...}: {
  #--------------------------------------------------------------------#
  #-- Configuration
  #--------------------------------------------------------------------#

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    historyWidget.zsh.command = ""; # let Atuin own Ctrl-R for zsh (avoids double-binding)
    colors = lib.mkForce {
      "fg+" = "#89b4fa";
      "bg+" = "-1";
      "fg" = "#cdd6f4";
      "bg" = "-1";
      "prompt" = "#45475a";
      "pointer" = "#89b4fa";
    };
    defaultOptions = [
      "--margin=1"
      "--layout=reverse"
      "--border=rounded"
      "--info='hidden'"
      "--header=''"
      "--prompt='/ '"
      "-i"
      "--no-bold"
    ];
  };
}

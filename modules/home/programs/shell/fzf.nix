#=====================================================================#
# FZF CONFIGURATION
#=====================================================================#
{
  config,
  lib,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Configuration
  #--------------------------------------------------------------------#

  #--- Colours: written by DMS's matugen (theme/matugen.nix); fzf exits if the
  #--- file is missing, so it starts empty until DMS first renders it
  home.sessionVariables.FZF_DEFAULT_OPTS_FILE = "${config.xdg.configHome}/fzf/dank.rc";
  home.activation.fzfColours = lib.hm.dag.entryAfter ["writeBoundary"] ''
    f="${config.xdg.configHome}/fzf/dank.rc"
    if [[ ! -v DRY_RUN && ! -e "$f" ]]; then
      mkdir -p "$(dirname "$f")" && : > "$f"
    fi
  '';

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    historyWidget.zsh.command = ""; # Atuin owns Ctrl-R (avoids double-binding)
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

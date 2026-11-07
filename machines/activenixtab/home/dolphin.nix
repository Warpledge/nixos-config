#=====================================================================#
# DOLPHIN: OPEN TERMINAL HERE
#=====================================================================#
#- KIO reads kdeglobals' General/TerminalApplication to pick the terminal,
#- and matugen rewrites that file from the repo template on each theme
#- change, so the key is written by that template's post_hook.
{
  config,
  pkgs,
  ...
}: let
  setTerminal = pkgs.writeShellScript "kdeglobals-terminal" ''
    exec ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file "${config.xdg.configHome}/kdeglobals" \
      --group General \
      --key TerminalApplication \
      "ghostty +new-window"
  '';
in {
  matugen.templates.kdeglobals.postHook = "${setTerminal}";
}

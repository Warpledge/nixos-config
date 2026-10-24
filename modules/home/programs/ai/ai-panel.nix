#=====================================================================#
# AI PANEL - CLAUDE CODE AND OPENCODE IN A LEFT-EDGE KITTY PANEL
#=====================================================================#
{
  config,
  lib,
  pkgs,
  user,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Panel
  #--------------------------------------------------------------------#

  #--- Running it again hides or shows the panel; the tabs keep running while hidden
  home.packages = [
    (pkgs.writeShellScriptBin "ai-panel" ''
      exec kitten quick-access-terminal --instance-group ai-panel \
        -c ${config.xdg.configHome}/kitty/ai-panel.conf "$@"
    '')
  ];

  xdg.configFile."kitty/ai-panel.conf".text = ''
    edge left
    columns 120
    focus_policy on-demand
    # Opaque like kitty.nix; niri's blur preset sets the translucency
    background_opacity 1.0
    kitty_override startup_session=ai-panel-session.conf
  '';

  #--- One tab per agent; --hold drops to a shell when the agent exits
  xdg.configFile."kitty/ai-panel-session.conf".text = lib.concatStringsSep "\n" (
    lib.optionals user.claude.enable [
      "new_tab Claude Code"
      "launch --hold claude"
    ]
    ++ lib.optionals user.opencode.enable [
      "new_tab opencode"
      "launch --hold opencode"
    ]
  );
}

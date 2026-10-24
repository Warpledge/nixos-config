#=====================================================================#
# AI PANEL - CLAUDE CODE AND OPENCODE IN A LEFT-EDGE KITTY PANEL
#=====================================================================#
{
  config,
  lib,
  machine,
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
    # Niri can't border a layer surface, so kitty draws it, 2px like the focus ring
    kitty_conf kitty.conf
    kitty_conf ai-panel-borders.conf
    kitty_override draw_window_borders_for_single_window=yes
    kitty_override window_border_width=2px
  '';

  #--- Border colours, rendered by DMS's matugen on each theme change
  matugen.templates.ai-panel = {
    input = ./ai-panel-borders.conf;
    output = "${config.xdg.configHome}/kitty/ai-panel-borders.conf";
  };

  #--- One tab per agent, opened in the config repo; --hold drops to a shell when the
  #--- agent exits
  xdg.configFile."kitty/ai-panel-session.conf".text = lib.concatStringsSep "\n" (
    ["cd ${machine.flakePath}"]
    ++ lib.optionals user.claude.enable [
      "new_tab Claude Code"
      "launch --hold claude"
    ]
    ++ lib.optionals user.opencode.enable [
      "new_tab opencode"
      "launch --hold opencode"
    ]
  );
}

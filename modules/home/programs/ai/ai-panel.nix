#=====================================================================#
# AI PANEL - A LEFT-EDGE KITTY PANEL FOR CLAUDE CODE AND OPENCODE
#=====================================================================#
{
  config,
  pkgs,
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
}

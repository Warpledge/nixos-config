#=====================================================================#
# ZEN BROWSER THEME (CATPPUCCIN MOCHA MAUVE)
#=====================================================================#
{config, ...}: {
  #--------------------------------------------------------------------#
  #-- Official Catppuccin Mocha Mauve Theme
  #--------------------------------------------------------------------#
  #--- Templates DMS's matugen fills on each theme change (theme/matugen.nix);
  #--- fixZenProfile links them into ~/.zen. Zen reads them on restart.
  #--- Not named .css: the {{ }} placeholders run Zed's biome out of memory.
  matugen.templates = let
    chrome = "${config.xdg.configHome}/zen/default/chrome";
  in {
    zen-chrome = {
      input = ./userChrome.css.matugen;
      output = "${chrome}/userChrome.css";
    };
    zen-content = {
      input = ./userContent.css.matugen;
      output = "${chrome}/userContent.css";
    };
  };
}

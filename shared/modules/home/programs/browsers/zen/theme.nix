#=====================================================================#
# ZEN BROWSER THEME (CATPPUCCIN MOCHA MAUVE)
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Official Catppuccin Mocha Mauve Theme
  #--------------------------------------------------------------------#
  userChrome = builtins.readFile ./userChrome.css;
  userContent = builtins.readFile ./userContent.css;
}

#=====================================================================#
# SKIM CONFIGURATION
#=====================================================================#
{
  #--------------------------------------------------------------------#
  #-- Configuration
  #--------------------------------------------------------------------#

  programs.skim = {
    enable = true;
    enableZshIntegration = false; # fzf owns Ctrl-T, Alt-C and **<Tab>
    defaultCommand = "rg --files --hidden";
    changeDirWidgetOptions = [
      "--preview 'eza --icons --git --color always -T -L 3 {} | head -200'"
      "--exact"
    ];
  };
}

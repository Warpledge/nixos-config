#=====================================================================#
# FONT CONFIGURATION
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Font Packages
  #--------------------------------------------------------------------#
  fonts = {
    packages = with pkgs; [
      #--- nerdfonts (coding)
      nerd-fonts.jetbrains-mono # Fallback
      nerd-fonts.monaspace # Modern monospace with texture healing
      nerd-fonts.symbols-only

      #--- icon fonts
      material-symbols

      #--- Japanese fonts (required for VNs, games, and Japanese web content)
      ipafont # General-purpose Japanese font
      kochi-substitute # Japanese serif font for traditional text
    ];
  };
}

#=====================================================================#
# FONT CONFIGURATION
#=====================================================================#
{
  lib,
  pkgs,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Font Packages
  #--------------------------------------------------------------------#
  fonts = {
    packages = with pkgs; [
      #--- nerdfonts (coding)
      nerd-fonts.jetbrains-mono # Fallback
      nerd-fonts.monaspace # Modern monospace with texture healing
      nerd-fonts.symbols-only

      #--- UI fonts
      roboto

      #--- icon fonts
      material-symbols

      #--- Japanese fonts (required for VNs, games, and Japanese web content)
      ipafont # General-purpose Japanese font
      kochi-substitute # Japanese serif font for traditional text
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
    ];

    #--- Japanese glyphs fall back to Noto CJK JP after Stylix's fonts, not IPAGothic
    fontconfig.defaultFonts = {
      sansSerif = lib.mkAfter ["Noto Sans CJK JP"];
      serif = lib.mkAfter ["Noto Serif CJK JP"];
      monospace = lib.mkAfter ["Noto Sans Mono CJK JP"];
    };
  };
}

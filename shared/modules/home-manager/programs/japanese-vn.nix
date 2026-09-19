#=====================================================================#
# JAPANESE VISUAL NOVEL & RAW GAME SUPPORT
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Tooling
  #--------------------------------------------------------------------#
  # Raw (untranslated) Japanese games: visual novels from DLSite, DMM GAMES
  # and similar. Reference: https://learnjapanese.moe/vn-linux/

  home.packages = with pkgs; [
    #--- Installer & archive extraction
    # DLSite/DMM downloads are commonly Inno Setup installers or disc images.
    innoextract # Unpack Inno Setup installers
    cabextract # Extract .cab archives bundled inside some installers
    mdf2iso # Convert .mdf/.mds disc images to .iso for mounting
  ];
}

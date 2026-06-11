#=====================================================================#
# JAPANESE VISUAL NOVEL & RAW GAME SUPPORT
#=====================================================================#
{pkgs, ...}: {
  #--------------------------------------------------------------------#
  #-- Tooling
  #--------------------------------------------------------------------#
  # Support for raw (untranslated) Japanese games — visual novels from
  # DLSite / DMM GAMES and similar. Wine/Proton, Lutris, CJK fonts, and the
  # JP locale already live in the gaming/theme/locale modules; this adds the
  # VN-specific glue. Reference: https://learnjapanese.moe/vn-linux/
  #
  # Mojibake fixes, Proton backends, RPG Maker quirks, and the per-game
  # launcher env vars / wrappers are documented in
  # .notes/gaming/launcher-env-variables.md (the ja_JP.UTF-8 locale they rely on is
  # already enabled in shared/modules/nixos/system/locale.nix).
  home.packages = with pkgs; [
    #--- Installer & archive extraction
    # DLSite/DMM downloads are commonly Inno Setup installers or disc images.
    innoextract # Unpack Inno Setup installers without executing them
    cabextract # Extract .cab archives bundled inside some installers
    mdf2iso # Convert .mdf/.mds disc images to .iso for mounting
  ];
}

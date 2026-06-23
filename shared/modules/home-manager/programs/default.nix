#=====================================================================#
# PROGRAMS MODULE IMPORTS
#=====================================================================#
{
  lib,
  hostConfig,
  ...
}: {
  #--------------------------------------------------------------------#
  #-- Module Imports
  #--------------------------------------------------------------------#
  imports =
    [
      #--- Editors (non-configurable)
      ./editors/micro.nix

      #--- Fetch
      ./fetch/fastfetch.nix

      #--- File Browsers (non-configurable)
      ./file-browsers/nautilus.nix

      #--- Media
      ./media/screen-capture.nix
      ./media/qr-scanner.nix

      #--- Shell
      ./shell/p10k/p10k.nix
      ./shell/atuin.nix
      ./shell/eza.nix
      ./shell/fzf.nix
      ./shell/skim.nix
      ./shell/starship.nix
      ./shell/tmux.nix
      ./shell/zoxide.nix
      ./shell/zsh.nix

      #--- Archives
      ./archives.nix

      #--- Other
      ./android.nix
      ./core.nix
      ./chat-clients/discord.nix
      ./gaming.nix
      ./git.nix
    ]
    #--- Browsers (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.browsers.zen [./browsers/zen]
    ++ lib.optionals hostConfig.browsers.mullvad [./browsers/mullvad]
    ++ lib.optionals hostConfig.browsers.helium [./browsers/helium]
    #--- Editors (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.editors.helix [./editors/helix.nix]
    ++ lib.optionals hostConfig.editors.zed [./editors/zed.nix]
    #--- Media (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.media.mpv [./media/mpv.nix]
    ++ lib.optionals hostConfig.media.spotify [./media/spotify.nix]
    ++ lib.optionals hostConfig.media.grayjay [./media/grayjay.nix]
    ++ lib.optionals hostConfig.media.videoTrimmer [./media/video-trimmer.nix]
    #--- Terminals (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.terminals.kitty [./terminals/kitty.nix]
    ++ lib.optionals hostConfig.terminals.ghostty [./terminals/ghostty.nix]
    #--- Creative (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.creative.blender [./creative/blender.nix]
    ++ lib.optionals hostConfig.creative.krita [./creative/krita.nix]
    ++ lib.optionals hostConfig.creative.affinity [./creative/affinity.nix]
    #--- Local Packages (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.local.katanaFxFloorBoard [./local/katana-fxfloorboard.nix]
    #--- WinBoat (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.winboat.enable [./emulation/winboat.nix]
    #--- AI Tools (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.claude.enable [./ai/claude.nix]
    ++ lib.optionals hostConfig.opencode.enable [./ai/opencode.nix]
    ++ lib.optionals hostConfig.lmstudio.enable [./ai/lmstudio.nix]
    #--- Japanese VN / Game Support (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.japanese.vn [./japanese-vn.nix]
    #--- Game Launchers (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.gameLaunchers.heroic [./launchers/heroic.nix]
    ++ lib.optionals hostConfig.gameLaunchers.prismlauncher [./launchers/prismlauncher.nix]
    ++ lib.optionals hostConfig.gameLaunchers.lutris [./launchers/lutris.nix]
    ++ lib.optionals hostConfig.gameLaunchers.faugus [./launchers/faugus.nix];
}

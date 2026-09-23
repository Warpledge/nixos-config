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

      #--- Media (non-configurable)
      ./media/screen-capture.nix

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

      #--- Other
      ./android/android.nix
      ./core.nix
      ./discord/discord.nix
      ./gaming/gaming.nix
      ./gaming/tml-prelaunch.nix
      ./git.nix
    ]
    #--- File Browsers (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.fileBrowsers.nautilus [./file-browsers/nautilus.nix]
    ++ lib.optionals hostConfig.fileBrowsers.yazi [./file-browsers/yazi.nix]
    #--- Browsers (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.browsers.zen [./browsers/zen]
    ++ lib.optionals hostConfig.browsers.mullvad [./browsers/mullvad]
    ++ lib.optionals hostConfig.browsers.helium [./browsers/helium]
    ++ lib.optionals hostConfig.browsers.ferdium [./browsers/ferdium.nix]
    #--- Editors (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.editors.helix [./editors/helix.nix]
    ++ lib.optionals hostConfig.editors.zed [./editors/zed.nix]
    #--- Media (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.media.mpv [./media/mpv.nix]
    ++ lib.optionals hostConfig.media.spotify [./media/spotify.nix]
    ++ lib.optionals hostConfig.media.freetube [./media/freetube]
    ++ lib.optionals hostConfig.media.videoTrimmer [./media/video-trimmer.nix]
    ++ lib.optionals hostConfig.media.mangayomi [./media/mangayomi.nix]
    ++ lib.optionals hostConfig.media.streamlinkTwitchGui [./media/streamlink-twitch-gui.nix]
    #--- Terminals (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.terminals.kitty [./terminals/kitty.nix]
    ++ lib.optionals hostConfig.terminals.ghostty [./terminals/ghostty.nix]
    #--- Graphics (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.graphics.blender [./graphics/blender.nix]
    ++ lib.optionals hostConfig.graphics.krita [./graphics/krita.nix]
    ++ lib.optionals hostConfig.graphics.affinity [./graphics/affinity.nix]
    #--- Audio (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.audio.reaper [./audio/reaper.nix]
    ++ lib.optionals hostConfig.audio.guitar [./audio/guitar.nix]
    ++ lib.optionals hostConfig.audio.feedback [./gaming/feedback.nix]
    #--- Office (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.office.thunderbird [./office/thunderbird.nix]
    ++ lib.optionals hostConfig.office.obsidian [./office/obsidian.nix]
    ++ lib.optionals hostConfig.office.homebank [./office/homebank.nix]
    #--- Security (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.security.bleachbit [./security/bleachbit.nix]
    #--- Local Packages (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.local.granblueRelinkMods [./local/relink-mod-organizer.nix ./local/reloaded-ii-gbfr.nix]
    ++ lib.optionals hostConfig.local.tonkatsuBox [./local/tonkatsu-box.nix]
    #--- WinBoat (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.winboat.enable [./emulation/winboat.nix]
    #--- Android Screen Mirroring (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.scrcpy.enable [./android/scrcpy.nix]
    #--- AI Tools (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.claude.enable [./ai/claude.nix]
    ++ lib.optionals hostConfig.opencode.enable [./ai/opencode.nix]
    ++ lib.optionals hostConfig.lmstudio.enable [./ai/lmstudio.nix]
    #--- Japanese VN / Game Support (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.japanese.vn [./gaming/japanese-vn.nix]
    #--- Discord Rich Presence / Game Detection (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.discord.arrpc.enable [./discord/arrpc.nix]
    #--- Game Launchers (controlled by host hostConfig.nix)
    ++ lib.optionals hostConfig.gameLaunchers.heroic [./launchers/heroic.nix]
    ++ lib.optionals hostConfig.gameLaunchers.prismlauncher [./launchers/prismlauncher.nix]
    ++ lib.optionals hostConfig.gameLaunchers.lutris [./launchers/lutris.nix]
    ++ lib.optionals hostConfig.gameLaunchers.faugus [./launchers/faugus.nix]
    ++ lib.optionals hostConfig.gameLaunchers.easyrpg [./launchers/easyrpg.nix];
}
